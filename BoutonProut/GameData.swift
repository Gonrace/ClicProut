import SwiftUI
import Combine
import Foundation
import MediaPlayer

// NOTE: Ce fichier gère l'état global du jeu, l'économie et la logique de combat.
// Nécessite : ShopModels.swift, ShopList_Standard.swift, ShopList_Cosmetics.swift, ShopList_PvP.swift et CombatLogic.swift


// MARK: - STRUCTURES D'AIDE
struct ActiveAttackInfo: Identifiable {
    let id: String           // L'ID de l'effet (ex: attack_dps_reduction_50)
    let attackerName: String // Nom de celui qui a envoyé l'attaque
    let weaponName: String   // Nom de l'arme utilisée
    let expiryDate: Date     // Date à laquelle l'attaque s'arrête
}

class GameData: ObservableObject {

    // MARK: - ÉCONOMIE ET MONNAIES
    @AppStorage("TotalFartCount") var totalFartCount: Int = 0      // Monnaie actuelle
    @AppStorage("LifetimeFarts") var lifetimeFarts: Int = 0        // Score total (Classement)
    @AppStorage("GoldenToiletPaper") var goldenToiletPaper: Int = 0 // Monnaie Premium
    
    // MARK: - ÉTAT DU JEU ET COMBAT
    @Published var autoFarterUpdateCount: Int = 0
    
    // Détails de la dernière attaque pour l'affichage rapide
    @Published var lastAttackerName: String = ""
    @Published var lastAttackWeapon: String = ""
    
    // Dictionnaire brut : [ID de l'effet : Date d'expiration]
    @Published var activeAttacks: [String: Date] = [:]
    
    @Published var petAccumulator: Double = 0.0 // Le réservoir pour les fractions de pets
    
    // DETECTION DU VOLUME UTILISATEUR
    @Published var isMuted: Bool = false
    
    func processProutClick() {
        // 1. On force la vérification du volume au moment du clic
        checkMuteStatus()
        
        // 2. On calcule le gain avec le multiplicateur actuel
        let produced = Int(Double(clickPower) * soundMultiplier)
        
        // 3. On met à jour les scores
        totalFartCount += produced
        lifetimeFarts += produced
    }
    
    // Ajoute cette fonction pour vérifier le volume
    func checkMuteStatus() {
        // On force la mise à jour de la session audio pour lire la valeur réelle
        let volume = AVAudioSession.sharedInstance().outputVolume
        
        // On utilise DispatchQueue pour être sûr que l'UI réagisse au changement
        DispatchQueue.main.async {
            // On considère "Muted" si le volume est inférieur à 0.1 (pour éviter les micro-bugs)
            self.isMuted = (volume < 0.1)
            
            // Debug pour voir dans la console si ça réagit
            print("🔈 Volume actuel: \(volume) | Malus activé: \(self.isMuted)")
        }
    }

    // MODIFIE ton multiplicateur global (ou la fonction qui calcule le gain)
    // Imaginons que tu as une variable globale de profit :
    var soundMultiplier: Double {
        return isMuted ? 0.1 : 1.0
    }
    
    // MARK: - PROPRIÉTÉS CALCULÉES POUR LE COMBAT
    
    /// Transforme le dictionnaire brut en une liste d'objets faciles à afficher dans CombatView
    var currentAttacks: [ActiveAttackInfo] {
        activeAttacks.map { (key, value) in
            ActiveAttackInfo(
                id: key,
                attackerName: lastAttackerName,
                weaponName: lastAttackWeapon,
                expiryDate: value
            )
        }.filter { $0.expiryDate > Date() } // On ne garde que celles qui ne sont pas finies
    }
    
    /// Raccourci pour savoir si le joueur subit au moins un malus
    var isUnderAttack: Bool {
        return !currentAttacks.isEmpty
    }
    
    // MARK: - INVENTAIRE ET NIVEAUX
    // Initialisation au démarrage avec chargement des données sauvegardées
    @Published var itemLevels: [String: Int] = [:] {
        didSet { GameData.saveItemLevels(itemLevels) }
    }
    
    init() {
        self.itemLevels = GameData.loadItemLevels()
        
        // --- NOUVEAU : DETECTION DU VOLUME ---
        // CONFIGURATION AUDIO OBLIGATOIRE
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Erreur configuration AudioSession: \(error)")
            }
        // 1. On vérifie l'état initial au lancement
        checkMuteStatus()
                
        // 2. On s'abonne aux changements de volume du système
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkMuteStatus()
        }
        
    }
    
    /// Fusion de toutes les listes de la boutique pour la logique de calcul
    var allItems: [ShopItem] {
        return standardShopItems + cosmeticShopItems + pvpShopItems
    }
    
    // MARK: - CALCULS DE PRODUCTION
    
    var prestigeMultiplier: Double { 1.0 }
    
    /// Calcul du PPS (Pets Par Seconde) avec intégration des malus PvP
    var petsPerSecond: Double {
        var totalDPS: Double = 0
        var globalDPSMultiplier: Double = 1.0
        
        // 1. Bonus passifs globaux
        if itemLevels["Tuyauterie XXL", default: 0] > 0 { globalDPSMultiplier *= 1.05 }
        if itemLevels["Climatisation", default: 0] > 0 { globalDPSMultiplier *= 1.10 }
        
        // 2. Production des bâtiments
        for item in standardShopItems.filter({ $0.category == .production }) {
            let count = itemLevels[item.name, default: 0]
            if count == 0 { continue }
            
            var itemDPS = Double(count) * (item.dpsRate / 10.0)
            
            // 3. Upgrades spécifiques
            if let upgrade = standardShopItems.first(where: { $0.category == .amelioration && $0.requiredItem == item.name }) {
                if itemLevels[upgrade.name, default: 0] > 0 {
                    // Gestion des multiplicateurs selon le nom de l'upgrade
                    if upgrade.name.contains("Triple") || upgrade.name.contains("Blague Beauf") {
                        itemDPS *= 3.0
                    } else if upgrade.name.contains("Sauce Piquante") {
                        itemDPS *= 2.0
                    }
                }
            }
            
            // Bonus Héritage (Acte IV)
            if item.name == "Haricot" || item.name == "Tonton Blagueur" {
                if itemLevels["Héritage", default: 0] > 0 { itemDPS *= 5.0 }
            }
            
            totalDPS += itemDPS
        }
        
        // 4. APPLICATION DES MALUS PvP (Lecture seule)
        let now = Date()
        for (effectID, expiryDate) in activeAttacks where expiryDate > now {
            if effectID == "attack_dps_reduction_50" {
                globalDPSMultiplier *= 0.5
            }
        }
        return totalDPS * globalDPSMultiplier * prestigeMultiplier * soundMultiplier
    }
    
    /// Calcul du PPC (Pets Par Clic)
    var clickPower: Int {
        var power: Double = 1.0
        var globalPPCMultiplier: Double = 1.0
        
        for item in standardShopItems.filter({ $0.category == .outil }) {
            let count = itemLevels[item.name, default: 0]
            power += Double(count * item.clickMultiplier)
        }
        
        if itemLevels["Double Clic", default: 0] > 0 { globalPPCMultiplier *= 2.0 }
        
        return Int(power * globalPPCMultiplier * soundMultiplier)
    }
    
    /// Taille visuelle du bouton prout selon la richesse
    var calculatedPoopScale: CGFloat {
        let baseSize: CGFloat = 1.0
        let growthFactor = CGFloat(totalFartCount) / 5000.0
        return min(baseSize + growthFactor, 2.5)
    }

    // MARK: - MOTEUR D'ACHAT
    func attemptPurchase(item: ShopItem) -> Bool {
            let level = itemLevels[item.name, default: 0]
            
            // 1. Logique Consommables (Attaques/Défenses)
            // On ne peut en acheter qu'un seul à la fois
            if item.isConsumable && level >= 1 {
                return false
            }
            
            // 2. Déterminer si l'objet est unique (Amélioration, Skin, etc.)
            let isSingleLevelItem = (
                item.category == .amelioration ||
                item.category == .defense ||
                item.category == .jalonNarratif ||
                item.category == .skin ||
                item.category == .sound ||
                item.category == .background
            )
            
            // 3. Calcul du coût (Inflation pour prod/outils)
            let cost: Int
            if item.category == .production || item.category == .outil {
                cost = Int(Double(item.baseCost) * pow(1.2, Double(level)))
            } else {
                cost = item.baseCost
            }
            
            // 4. Bloquer si déjà possédé et non consommable
            if isSingleLevelItem && !item.isConsumable && level > 0 { return false }
            
            // 5. VÉRIFICATION CRUCIALE DES PRÉ-REQUIS
            if let req = item.requiredItem, let reqCount = item.requiredItemCount {
                if itemLevels[req, default: 0] < reqCount {
                    return false // Empêche l'achat si les 10 objets ne sont pas là
                }
            }
            
            // 6. Paiement
            if item.currency == .pets {
                guard totalFartCount >= cost else { return false }
                totalFartCount -= cost
            } else {
                guard goldenToiletPaper >= cost else { return false }
                goldenToiletPaper -= cost
            }
            
            // 7. Mise à jour de l'inventaire
            if isSingleLevelItem {
                itemLevels[item.name] = 1
            } else {
                itemLevels[item.name, default: 0] += 1
            }
            
            if item.category == .production {
                autoFarterUpdateCount += 1
            }

            return true
        }
    // MARK: - SYSTÈME DE COMBAT & DÉFENSE
    
    /// Nettoyage des attaques expirées (À appeler via Timer dans GameManager)
    func updateAttacksState() {
        let now = Date()
        let expiredKeys = activeAttacks.filter { $0.value <= now }.map { $0.key }
        
        if !expiredKeys.isEmpty {
            DispatchQueue.main.async {
                for key in expiredKeys {
                    self.activeAttacks.removeValue(forKey: key)
                }
            }
        }
    }

    /// Tente d'utiliser un objet de défense pour contrer une attaque en cours
    func tryDefend(with item: ShopItem) -> String {
        // 1. Vérifier si c'est bien une défense
        guard item.category == .defense, let defenseID = item.effectID else {
            return "Cet objet n'est pas une défense !"
        }
        
        // 2. Vérifier si le joueur en a en stock
        guard itemLevels[item.name, default: 0] > 0 else {
            return "Tu n'as plus de \(item.name) dans ton armoire !"
        }
        
        // --- ACTION : ON CONSOMME L'OBJET SYSTÉMATIQUEMENT ---
        // Le joueur perd l'objet dès qu'il clique, même s'il se trompe.
        itemLevels[item.name, default: 0] -= 1
        
        // 3. Chercher si cet objet contre une des attaques actives
        for (activeAttackID, _) in activeAttacks {
            if CombatLogic.canDefend(attackID: activeAttackID, defenseID: defenseID) {
                // SUCCÈS : On arrête l'attaque
                activeAttacks.removeValue(forKey: activeAttackID)
                return "Défense réussie ! L'attaque a été annulée."
            }
        }
        
        // 4. ÉCHEC : L'objet est perdu mais l'attaque continue
        if isUnderAttack {
            return "Ce n'est pas très efficace... Objet gaspillé !"
        } else {
            return "Tu as utilisé ça pour rien, tu n'étais même pas attaqué !"
        }
    }
    
    /// Applique une attaque reçue (depuis Firebase ou Événement)
    func applyAttack(effectID: String, duration: Int, attackerName: String = "Inconnu", weaponName: String = "une attaque") {
        let expiryDate = Date().addingTimeInterval(TimeInterval(duration * 60))
        
        DispatchQueue.main.async {
            self.lastAttackerName = attackerName
            self.lastAttackWeapon = weaponName
            self.activeAttacks[effectID] = expiryDate
            
            // Effet immédiat pour le vol de T1
            if effectID == "attack_loss_t1_10" {
                let currentLevel = self.itemLevels["Haricot", default: 0]
                let loss = Int(Double(currentLevel) * 0.10)
                self.itemLevels["Haricot"] = max(0, currentLevel - loss)
            }
        }
    }

    
    // DEBLOCAGE DES ACTE
    func isActeUnlocked(_ acte: Int) -> Bool {
        if acte == 1 { return true } // L'acte 1 est toujours ouvert
        
        let actePrecedent = acte - 1
        let itemsDeLActe = allItems.filter { $0.acte == actePrecedent }
        
        // On compte combien d'objets l'utilisateur possède au moins au niveau 1
        let itemsPossedes = itemsDeLActe.filter { itemLevels[$0.name, default: 0] > 0 }
        
        let pourcentageCompletion = Double(itemsPossedes.count) / Double(itemsDeLActe.count)
        
        return pourcentageCompletion >= 0.90
    }
    
    // BARRE PROGRESSION ACTE
    var currentActeProgress: Double {
        // 1. Trouver quel est l'acte actuel (le plus haut débloqué)
        var currentActe = 1
        for i in 2...5 {
            if isActeUnlocked(i) { currentActe = i }
        }
        
        // 2. Récupérer les items de cet acte
        let itemsInActe = allItems.filter { $0.acte == currentActe }
        if itemsInActe.isEmpty { return 0.0 }
        
        // 3. Compter combien sont possédés (au moins niveau 1)
        let ownedCount = itemsInActe.filter { itemLevels[$0.name, default: 0] > 0 }.count
        
        // 4. Retourner le ratio
        return Double(ownedCount) / Double(itemsInActe.count)
    }
    
    // MARK: - DÉBOGAGE ET HELPERS
    
    func hardReset() {
        self.totalFartCount = 0
        self.lifetimeFarts = 0
        self.goldenToiletPaper = 0
        self.itemLevels = [:]
        self.activeAttacks = [:]
        self.petAccumulator = 0.0
        
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "TotalFartCount")
        defaults.removeObject(forKey: "LifetimeFarts")
        defaults.removeObject(forKey: "GoldenToiletPaper")
        defaults.removeObject(forKey: "SavedItemLevels")
        defaults.synchronize()
        
        print("REINITIALISATION TOTALE EFFECTUÉE ⚠️")
    }
    
    func softReset() {
        self.totalFartCount = 0
        self.goldenToiletPaper = 0
        self.itemLevels = [:]
        self.activeAttacks = [:]
    }

    func addCheatPets() {
        self.totalFartCount += 1_000_000_000
        self.lifetimeFarts += 1_000_000_000
    }
        
    func addCheatGoldenPaper() {
        self.goldenToiletPaper += 999
    }
    
    var ownedItemsDisplay: [String] {
        return allItems
            .filter { $0.category == .outil }
            .compactMap { item in
                let value = itemLevels[item.name, default: 0]
                return value > 0 ? "\(item.emoji) \(value)" : nil
            }
    }

    // MARK: - PERSISTANCE PRIVÉE
    
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
}

import SwiftUI
import MediaPlayer

struct VolumeObserver: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.alpha = 0.001 // Presque invisible mais présent
        view.addSubview(volumeView)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
