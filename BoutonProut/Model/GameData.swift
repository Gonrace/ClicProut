import SwiftUI
import Combine
import Foundation
import MediaPlayer
import AVFoundation
import FirebaseDatabase

// MARK: - STRUCTURES D'AIDE
struct ActiveAttackInfo: Identifiable {
    let id: String           // ex: atk_spray
    let attackerName: String
    let weaponName: String
    let expiryDate: Date
    let multPPS: Double
    let multPPC: Double
}

struct GlobalConfig {
    var priceMultiplier: Double = 1.2
    var baseClickValue: Int = 1
}

class GameData: ObservableObject {
    
    private var ref = Database.database().reference()
    
    // MARK: - DONNÉES CLOUD (Synchronisées)
    @Published var allItems: [ShopItem] = []
    @Published var actesInfo: [Int: ActeMetadata] = [:]
    @Published var config = GlobalConfig()
    
    // MARK: - ÉCONOMIE ET MONNAIES (Local)
    @AppStorage("TotalFartCount") var totalFartCount: Int = 0
    @AppStorage("LifetimeFarts") var lifetimeFarts: Int = 0
    @AppStorage("GoldenToiletPaper") var goldenToiletPaper: Int = 0
    
    // MARK: - ÉTAT DU JEU ET COMBAT
    @Published var autoFarterUpdateCount: Int = 0
    @Published var activeAttacks: [String: ActiveAttackInfo] = [:]
    @Published var petAccumulator: Double = 0.0
    
    @Published var lastAttackerName: String = ""
    @Published var lastAttackWeapon: String = ""
    
    @Published var isMuted: Bool = false
    
    @Published var itemLevels: [String: Int] = [:] {
        didSet { GameData.saveItemLevels(itemLevels) }
    }

    // MARK: - INITIALISATION
    init() {
        self.itemLevels = GameData.loadItemLevels()
        startFirebaseSync()
        startGiftSync()
        setupAudioSession()
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"),
            object: nil, queue: .main
        ) { [weak self] _ in self?.checkMuteStatus() }
    }

    // MARK: - SYNC FIREBASE
    func startFirebaseSync() {
        ref.child("shop_items").observe(.value) { snapshot in
            guard let value = snapshot.value as? [String: [String: Any]] else { return }
            let items = value.values.compactMap { self.parseItem(dict: $0) }
            DispatchQueue.main.async {
                self.allItems = items
                print("✅ Firebase: \(items.count) objets chargés.")
            }
        }
        
        // Observer les Actes (Version robuste)
        ref.child("metadata_actes").observe(.value) { snapshot in
            var fetchedDict: [String: [String: Any]] = [:]
            
            // Firebase peut renvoyer soit [Dict], soit [Array] si les clés sont des chiffres
            if let array = snapshot.value as? [Any] {
                for (index, val) in array.enumerated() {
                    if let dict = val as? [String: Any] {
                        fetchedDict["\(index)"] = dict
                    }
                }
            } else if let dict = snapshot.value as? [String: [String: Any]] {
                fetchedDict = dict
            }

            var newActes: [Int: ActeMetadata] = [:]
            for (_, dict) in fetchedDict {
                // Correction : On s'assure que l'ID est bien extrait
                let rawID = dict["Acte"] ?? 0
                if let id = Int("\(rawID)"), id > 0 {
                    newActes[id] = ActeMetadata(
                        id: id,
                        title: dict["Titre"] as? String ?? "Acte \(id)",
                        description: dict["Description"] as? String ?? "",
                        threshold: Double("\(dict["Seuil_Deblocage"] ?? 0.9)") ?? 0.9
                    )
                }
            }
            
            DispatchQueue.main.async {
                self.actesInfo = newActes
                print("📖 Actes chargés : \(newActes.count)")
            }
        }

        ref.child("logic_pvp").observe(.value) { snapshot in
            guard let value = snapshot.value as? [String: [String: Any]] else { return }
            var logic: [String: [String]] = [:]
            for (_, dict) in value {
                if let atk = dict["Attack_Effect_ID"] as? String,
                   let def = dict["Defense_Effect_ID"] as? String {
                    logic[atk, default: []].append(def)
                }
            }
            CombatLogic.defensesForAttack = logic
        }
        
        // Observer la Config Globale
            ref.child("global_config").observe(.value) { snapshot in
                guard let value = snapshot.value as? [String: [String: Any]] else { return }
                DispatchQueue.main.async {
                    // Multiplicateur de prix
                    if let pMult = Double("\(value["price_multiplier"]?["Valeur"] ?? 1.2)") {
                        self.config.priceMultiplier = pMult
                    }
                        
                    // Puissance de clic de base
                    if let bClick = Int("\(value["base_click_value"]?["Valeur"] ?? 1)") {
                        self.config.baseClickValue = bClick
                    }
                        
                    // Statut du serveur (Exemple d'utilisation)
                    let status = value["server_status"]?["Valeur"] as? String ?? "online"
                    if status == "maintenance" {
                        print("⚠️ Le serveur est en mode maintenance !")
                        // Ici tu pourrais lever un flag pour bloquer l'accès au PVP
                    }
                        
                    print("⚙️ Config Cloud synchronisée")
                }
            }
    }

    private func parseItem(dict: [String: Any]) -> ShopItem? {
        guard let name = dict["Nom"] as? String else { return nil }
        let toDouble = { (v: Any?) -> Double in
            if let d = v as? Double { return d }
            if let s = v as? String { return Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0.0 }
            return Double("\(v ?? 0)") ?? 0.0
        }
        return ShopItem(
            name: name,
            category: ItemCategory(rawValue: dict["Categorie"] as? String ?? "production") ?? .production,
            acte: Int("\(dict["Acte"] ?? 1)") ?? 1,
            baseCost: Int("\(dict["Cout_Base"] ?? 0)") ?? 0,
            currency: (dict["Monnaie"] as? String == "goldenPaper") ? .goldenPaper : .pets,
            dpsRate: toDouble(dict["PPS_Rate"]),
            clickMultiplier: Int("\(dict["PPC_Bonus"] ?? 0)") ?? 0,
            multPPS: toDouble(dict["Mult_PPS"]) == 0 ? 1.0 : toDouble(dict["Mult_PPS"]),
            multPPC: toDouble(dict["Mult_PPC"]) == 0 ? 1.0 : toDouble(dict["Mult_PPC"]),
            lossRate: toDouble(dict["Loss_Rate"]),
            durationSec: Int("\(dict["Duration_Sec"] ?? 0)") ?? 0,
            emoji: dict["Emoji"] as? String ?? "❓",
            description: dict["Description"] as? String ?? "",
            requiredItem: (dict["Req_Item"] as? String == "" || dict["Req_Item"] as? String == nil) ? nil : dict["Req_Item"] as? String,
            requiredItemCount: Int("\(dict["Req_Count"] ?? 0)") ?? 0,
            effectID: dict["Effect_ID"] as? String == "" ? nil : dict["Effect_ID"] as? String
        )
    }

    // MARK: - LOGIQUE DE GAIN
    func processProutClick() {
        checkMuteStatus()
        let produced = clickPower
        totalFartCount += produced
        lifetimeFarts += produced
    }
    
    func checkMuteStatus() {
        let volume = AVAudioSession.sharedInstance().outputVolume
        DispatchQueue.main.async { self.isMuted = (volume < 0.1) }
    }

    var soundMultiplier: Double { isMuted ? 0.1 : 1.0 }

    var petsPerSecond: Double {
        var totalPPS: Double = 0
        var globalMultiplier: Double = 1.0
        for item in allItems.filter({ $0.category == .production }) {
            let count = itemLevels[item.name, default: 0]
            if count > 0 {
                var itemPPS = Double(count) * item.dpsRate
                let upgrades = allItems.filter { $0.category == .amelioration && $0.requiredItem == item.name }
                for upgrade in upgrades where itemLevels[upgrade.name, default: 0] > 0 {
                    itemPPS *= upgrade.dpsRate
                }
                totalPPS += itemPPS
            }
        }
        let now = Date()
        for attack in activeAttacks.values where attack.expiryDate > now {
            globalMultiplier *= attack.multPPS
        }
        return totalPPS * globalMultiplier * soundMultiplier
    }

    var clickPower: Int {
        var power: Double = Double(config.baseClickValue)
        var globalAttackMultiplier: Double = 1.0
        for item in allItems.filter({ $0.category == .outil }) {
            let count = itemLevels[item.name, default: 0]
            power += Double(count * item.clickMultiplier)
        }
        let now = Date()
        for attack in activeAttacks.values where attack.expiryDate > now {
            globalAttackMultiplier *= attack.multPPC
        }
        return Int(power * globalAttackMultiplier * soundMultiplier)
    }

    // MARK: - PROGRESSION NARRATIVE
    var currentActeProgress: Double {
        let currentActe = actesInfo.keys.filter { isActeUnlocked($0) }.max() ?? 1
        let itemsInActe = allItems.filter {
            $0.acte == currentActe && $0.category != .perturbateur && $0.category != .defense
        }
        if itemsInActe.isEmpty { return 0.0 }
        let ownedCount = itemsInActe.filter { itemLevels[$0.name, default: 0] > 0 }.count
        return Double(ownedCount) / Double(itemsInActe.count)
    }
    
    // MARK: - AFFICHAGE INTERFACE
        
    // Cette variable crée la liste d'emojis (ex: "💩 5", "🚽 2") pour l'inventaire rapide
    var ownedItemsDisplay: [String] {
        return allItems.filter { item in
            let level = itemLevels[item.name, default: 0]
            // On n'affiche que les bâtiments de production et les outils possédés
            return level > 0 && (item.category == .production || item.category == .outil)
        }.map { item in
            let level = itemLevels[item.name, default: 0]
            return "\(item.emoji) \(level)"
        }
    }

    // MARK: - MOTEUR D'ACHAT
    func attemptPurchase(item: ShopItem) -> Bool {
        let level = itemLevels[item.name, default: 0]
        if item.isConsumable && level >= 1 { return false }
        let isSingleLevel = (item.category == .amelioration || item.category == .defense || item.category == .jalonNarratif)
        let cost = (item.category == .production || item.category == .outil) ?
            Int(Double(item.baseCost) * pow(config.priceMultiplier, Double(level))) : item.baseCost
        if isSingleLevel && level > 0 { return false }
        if let req = item.requiredItem, itemLevels[req, default: 0] < (item.requiredItemCount ?? 0) { return false }
        if item.currency == .pets {
            guard totalFartCount >= cost else { return false }
            totalFartCount -= cost
        } else {
            guard goldenToiletPaper >= cost else { return false }
            goldenToiletPaper -= cost
        }
        if isSingleLevel { itemLevels[item.name] = 1 }
        else { itemLevels[item.name, default: 0] += 1 }
        if item.category == .production { autoFarterUpdateCount += 1 }
        return true
    }
    
    // Variable pour lister les attaques actives
    var currentAttacks: [ActiveAttackInfo] {
        activeAttacks.values
            .filter { $0.expiryDate > Date() }
            .sorted(by: { $0.expiryDate < $1.expiryDate })
    }
    // VÉRIFICATION DE L'EFFET UNLOCK_KADO ---
    var isGentillesseUnlocked: Bool {
        // On cherche dans itemLevels si l'item qui possède l'Effect_ID "unlock_kado" est au niveau 1
        return itemLevels.keys.contains { itemName in
            let itemData = allItems.first(where: { $0.name == itemName })
            return itemData?.effectID == "unlock_kado" && itemLevels[itemName, default: 0] > 0
        }
    }
    // MARK: - GESTION DES CADEAUX (KDO)
        
    // Écouteur Firebase pour les cadeaux
    func startGiftSync() {
        guard let userID = UIDevice.current.identifierForVendor?.uuidString else { return }
            
        ref.child("users").child(userID).child("gifts").observe(.childAdded) { snapshot in
            // On récupère les infos du cadeau
            guard let value = snapshot.value as? [String: Any],
                    let giftID = value["giftID"] as? String,
                    let sender = value["senderName"] as? String else { return }
                
            // --- CONDITION : ON NE TRAITE LE CADEAU QUE SI L'ITEM EST ACHETÉ ---
            if self.isGentillesseUnlocked {
                DispatchQueue.main.async {
                    self.processIncomingGift(giftID: giftID, from: sender)
                    // On supprime le cadeau de la base après l'avoir "consommé"
                    snapshot.ref.removeValue()
                }
            } else {
                print("🎁 Cadeau en attente : débloquez la Gentillesse pour le recevoir.")
            }
        }
    }

    private func processIncomingGift(giftID: String, from: String) {
        // On cherche l'objet dans allItems via son effectID
        guard let giftItem = allItems.first(where: { $0.effectID == giftID }) else {
            print("⚠️ Cadeau inconnu (ID: \(giftID))")
            return
        }

        let nomKdo = giftItem.name

        DispatchQueue.main.async {
            if giftItem.durationSec > 0 {
                // CAS A : Boost temporaire (on utilise la structure des attaques car petsPerSecond les gère déjà)
                let info = ActiveAttackInfo(
                    id: giftID + "_\(UUID().uuidString)",
                    attackerName: from,
                    weaponName: nomKdo,
                    expiryDate: Date().addingTimeInterval(TimeInterval(giftItem.durationSec)),
                    multPPS: giftItem.multPPS,
                    multPPC: giftItem.multPPC
                )
                self.activeAttacks[info.id] = info
                print("🚀 Cadeau reçu ! '\(nomKdo)' envoyé par \(from).")

            } else {
                // CAS B : Gain instantané
                if giftItem.dpsRate > 0 {
                    let montant = Int(giftItem.dpsRate)
                    self.totalFartCount += montant
                    self.lifetimeFarts += montant
                    print("🎁 Cadeau reçu ! '\(nomKdo)' de \(from) : +\(montant) Pets !")
                }
                    
                if giftItem.clickMultiplier > 0 {
                    let montantOr = giftItem.clickMultiplier
                    self.goldenToiletPaper += montantOr
                    print("👑 Cadeau reçu ! '\(nomKdo)' de \(from) : +\(montantOr) PQ d'Or !")
                }
            }
        }
    }

    // MARK: - DEBLOCAGE ATTAQUE

    // Indique si le joueur est actuellement sous le coup d'une attaque
    var isUnderAttack: Bool {
        !currentAttacks.isEmpty
    }

    // (Optionnel mais utile) Retourne l'attaque la plus urgente
    var activeAttackCount: Int {
        currentAttacks.count
    }
    
    func tryDefend(with item: ShopItem) -> String {
        guard item.category == .defense, let defenseID = item.effectID else { return "Pas une défense !" }
        guard itemLevels[item.name, default: 0] > 0 else { return "Plus de stock !" }
        itemLevels[item.name, default: 0] -= 1
        for (activeAttackID, _) in activeAttacks {
            if CombatLogic.canDefend(attackID: activeAttackID, defenseID: defenseID) {
                activeAttacks.removeValue(forKey: activeAttackID)
                return "Défense réussie !"
            }
        }
        return !activeAttacks.isEmpty ? "Échec... Objet perdu !" : "Utilisé dans le vide !"
    }

    func isActeUnlocked(_ acte: Int) -> Bool {
        if acte == 1 { return true }
        let itemsPrecedent = allItems.filter { $0.acte == acte - 1 && ($0.category == .production || $0.category == .outil) }
        if itemsPrecedent.isEmpty { return false }
        let owned = itemsPrecedent.filter { itemLevels[$0.name, default: 0] > 0 }
        let threshold = actesInfo[acte]?.threshold ?? 0.9
        return Double(owned.count) / Double(itemsPrecedent.count) >= threshold
    }

    func hardReset() {
        totalFartCount = 0
        lifetimeFarts = 0
        goldenToiletPaper = 0
        itemLevels.removeAll()
        activeAttacks.removeAll()
        UserDefaults.standard.removeObject(forKey: "SavedItemLevels")
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { print("Audio Error") }
    }

    private static func saveItemLevels(_ levels: [String: Int]) {
        if let encoded = try? JSONEncoder().encode(levels) {
            UserDefaults.standard.set(encoded, forKey: "SavedItemLevels")
        }
    }

    private static func loadItemLevels() -> [String: Int] {
        if let data = UserDefaults.standard.data(forKey: "SavedItemLevels"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            return decoded
        }
        return [:]
    }
    // MARK: - GESTION DES ATTAQUES ENTRANTES
        
    func applyAttack(effectID: String, duration: Int, attackerName: String, weaponName: String) {
        // On cherche les statistiques de l'arme (multPPS, multPPC) dans allItems
        // allItems contient maintenant les données reçues de Firebase (ex-CSV)
        guard let itemData = allItems.first(where: { $0.effectID == effectID }) else {
            print("⚠️ Attaque reçue mais l'item \(effectID) est inconnu dans la boutique.")
            return
        }
            
        let info = ActiveAttackInfo(
            id: effectID,
            attackerName: attackerName,
            weaponName: weaponName,
            // duration est en minutes dans Firebase, on convertit en secondes pour iOS
            expiryDate: Date().addingTimeInterval(TimeInterval(duration * 60)),
            multPPS: itemData.multPPS,
            multPPC: itemData.multPPC
        )
            
        DispatchQueue.main.async {
            self.lastAttackerName = attackerName
            self.lastAttackWeapon = weaponName
            // On ajoute l'attaque au dictionnaire : cela déclenche le recalcul auto des PPS/PPC
            self.activeAttacks[effectID] = info
            print("🚀 Attaque appliquée : \(weaponName) par \(attackerName)")
        }
    }
}
