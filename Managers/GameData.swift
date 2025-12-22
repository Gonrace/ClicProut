import SwiftUI
import Combine
import Foundation
import MediaPlayer
import AVFoundation
import AudioToolbox

// MARK: - STRUCTURES D'AIDE
struct ActiveAttackInfo: Identifiable {
    let id: String           // ex: atk_spray
    let attackerName: String
    let weaponName: String
    let expiryDate: Date
    let multPPS: Double
    let multPPC: Double
}

struct ReceivedGiftInfo: Identifiable {
    let id = UUID()
    let senderName: String
    let giftName: String
    let emoji: String
    let date: Date
}

// Note: GlobalConfig est maintenant géré par CloudConfigManager,
// mais on garde la structure pour la compatibilité si besoin.
struct GlobalConfig {
    var priceMultiplier: Double = 1.2
    var baseClickValue: Int = 1
}

class GameData: ObservableObject {
    // Référence vers le manager de données Cloud
    var cloudManager: CloudConfigManager?
    
    // MARK: - NOTIFICATION
    @Published var pendingNotification: GameNotification? = nil
    @Published var showNotificationOverlay: Bool = false
    
    // MARK: - ÉCONOMIE (Local)
    @AppStorage("TotalFartCount") var totalFartCount: Int = 0
    @AppStorage("LifetimeFarts") var lifetimeFarts: Int = 0
    @AppStorage("GoldenToiletPaper") var goldenToiletPaper: Int = 0
    
    // MARK: - ÉTAT DU JEU ET ECHANGE
    @Published var autoFarterUpdateCount: Int = 0
    @Published var activeAttacks: [String: ActiveAttackInfo] = [:]
    @Published var receivedGifts: [ReceivedGiftInfo] = []

    @Published var petAccumulator: Double = 0.0
    @Published var lastAttackerName: String = ""
    @Published var lastAttackWeapon: String = ""
    @Published var isMuted: Bool = false
    
    @Published var itemLevels: [String: Int] = [:] {
        didSet {
            GameData.saveItemLevels(itemLevels)
            self.checkNotifications()
        }
    }

    // MARK: - INITIALISATION
    init() {
        self.itemLevels = GameData.loadItemLevels()
        setupAudioSession()
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"),
            object: nil, queue: .main
        ) { [weak self] _ in self?.checkMuteStatus() }
    }

    // MARK: - LOGIQUE DE GAIN
    func processProutClick() {
        checkMuteStatus()
        let produced = clickPower
        totalFartCount += produced
        lifetimeFarts += produced
        checkNotifications()
    }
    
    func checkMuteStatus() {
        let volume = AVAudioSession.sharedInstance().outputVolume
        DispatchQueue.main.async { self.isMuted = (volume < 0.1) }
    }

    var soundMultiplier: Double { isMuted ? 0.1 : 1.0 }

    var petsPerSecond: Double {
        // CORRECTION : On pointe vers cloudManager.allItems
        guard let items = cloudManager?.allItems else { return 0 }
        var totalPPS: Double = 0
        var globalMultiplier: Double = 1.0
        
        for item in items.filter({ $0.category == .production }) {
            let count = itemLevels[item.name, default: 0]
            if count > 0 {
                var itemPPS = Double(count) * item.dpsRate
                let upgrades = items.filter { $0.category == .amelioration && $0.requiredItem == item.name }
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
        // CORRECTION : On pointe vers cloudManager.allItems et cloudManager.config
        guard let items = cloudManager?.allItems else { return 1 }
        let baseValue = cloudManager?.config.baseClickValue ?? 1
        
        var power: Double = Double(baseValue)
        var globalAttackMultiplier: Double = 1.0
        
        for item in items.filter({ $0.category == .outil }) {
            let count = itemLevels[item.name, default: 0]
            power += Double(count * item.clickMultiplier)
        }
        let now = Date()
        for attack in activeAttacks.values where attack.expiryDate > now {
            globalAttackMultiplier *= attack.multPPC
        }
        return Int(power * globalAttackMultiplier * soundMultiplier)
    }

    // MARK: - PROGRESSION
    var currentActeProgress: Double {
        guard let items = cloudManager?.allItems,
              let actes = cloudManager?.actesInfo else { return 0 }
        
        let currentActe = actes.keys.filter { isActeUnlocked($0) }.max() ?? 1

        let itemsInActe = items.filter {
            $0.acte == currentActe && $0.category != .perturbateur && $0.category != .defense
        }
        if itemsInActe.isEmpty { return 0.0 }
        let ownedCount = itemsInActe.filter { itemLevels[$0.name, default: 0] > 0 }.count
        return Double(ownedCount) / Double(itemsInActe.count)
    }
    
    var ownedItemsDisplay: [String] {
        guard let items = cloudManager?.allItems else { return [] }
        return items.filter { item in
            let level = itemLevels[item.name, default: 0]
            return level > 0 && (item.category == .production || item.category == .outil)
        }.map { item in
            let level = itemLevels[item.name, default: 0]
            return "\(item.emoji) \(level)"
        }
    }
    
    func isActeUnlocked(_ acte: Int) -> Bool {
        if acte == 1 { return true }
        guard let items = cloudManager?.allItems,
              let actes = cloudManager?.actesInfo else { return false }
        
        let itemsPrecedent = items.filter { $0.acte == acte - 1 && ($0.category == .production || $0.category == .outil) }
        if itemsPrecedent.isEmpty { return false }
        let owned = itemsPrecedent.filter { itemLevels[$0.name, default: 0] > 0 }
        let threshold = actes[acte]?.threshold ?? 0.9
        return Double(owned.count) / Double(itemsPrecedent.count) >= threshold
    }

    // MARK: - LOGIQUE DE DÉCOUVERTE
    var isMechanceteUnlocked: Bool {
        guard let items = cloudManager?.allItems else { return false }
        return itemLevels.keys.contains { itemName in
            let itemData = items.first(where: { $0.name == itemName })
            return itemData?.effectID == "unlock_combat" && itemLevels[itemName, default: 0] > 0
        }
    }

    var isGentillesseUnlocked: Bool {
        guard let items = cloudManager?.allItems else { return false }
        return itemLevels.keys.contains { itemName in
            let itemData = items.first(where: { $0.name == itemName })
            return itemData?.effectID == "unlock_kado" && itemLevels[itemName, default: 0] > 0
        }
    }

    var hasDiscoveredInteractions: Bool {
        isMechanceteUnlocked || isGentillesseUnlocked
    }


    // MARK: - MOTEUR D'ACHAT
    func attemptPurchase(item: ShopItem) -> Bool {
        let level = itemLevels[item.name, default: 0]
        if item.isConsumable && level >= 1 { return false }
        
        let isSingleLevel = (item.category == .amelioration || item.category == .defense || item.category == .jalonNarratif || item.category == .kado)
        
        // CORRECTION : On utilise le prix du cloudManager
        let multiplier = cloudManager?.config.priceMultiplier ?? 1.2
        let cost = (item.category == .production || item.category == .outil) ?
            Int(Double(item.baseCost) * pow(multiplier, Double(level))) : item.baseCost
            
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
        checkNotifications()
        return true
    }

    // MARK: - LOGIQUE DES INTERACTIONS
    var isUnderAttack: Bool { !currentAttacks.isEmpty }
    
    var currentAttacks: [ActiveAttackInfo] {
        activeAttacks.values
            .filter { $0.expiryDate > Date() }
            .sorted(by: { $0.expiryDate < $1.expiryDate })
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

    func applyGift(giftID: String, from: String) {
        guard let items = cloudManager?.allItems,
              let giftItem = items.first(where: { $0.effectID == giftID }) else { return }
        
        DispatchQueue.main.async {
            if giftItem.dpsRate > 0 { self.totalFartCount += Int(giftItem.dpsRate) }
            if giftItem.clickMultiplier > 0 { self.goldenToiletPaper += giftItem.clickMultiplier }
            let newGift = ReceivedGiftInfo(senderName: from, giftName: giftItem.name, emoji: giftItem.emoji, date: Date())
            self.receivedGifts.insert(newGift, at: 0)
            
            self.pendingNotification = GameNotification(
                id: UUID().uuidString,
                title: "🎁 CADEAU REÇU !",
                message: "\(from) t'a envoyé : \(giftItem.name) ! \(giftItem.emoji)",
                conditionType: "direct",
                conditionValue: ""
            )
            self.showNotificationOverlay = true
            AudioServicesPlaySystemSound(1002)
        }
    }

    func applyAttack(effectID: String, duration: Int, attackerName: String, weaponName: String) {
        guard let items = cloudManager?.allItems,
              let itemData = items.first(where: { $0.effectID == effectID }) else { return }
        
        let info = ActiveAttackInfo(
            id: effectID,
            attackerName: attackerName,
            weaponName: weaponName,
            expiryDate: Date().addingTimeInterval(TimeInterval(duration * 60)),
            multPPS: itemData.multPPS,
            multPPC: itemData.multPPC
        )
        
        DispatchQueue.main.async {
            self.lastAttackerName = attackerName
            self.lastAttackWeapon = weaponName
            self.activeAttacks[effectID] = info
            
            self.pendingNotification = GameNotification(
                id: UUID().uuidString,
                title: "🚀 ATTAQUE REÇUE !",
                message: "\(attackerName) t'a balancé : \(weaponName) ! \(itemData.emoji)",
                conditionType: "direct",
                conditionValue: ""
            )
            self.showNotificationOverlay = true
            AudioServicesPlaySystemSound(1005)
        }
    }

    // MARK: - SYSTEME & RESET
    func hardReset() {
        totalFartCount = 0; lifetimeFarts = 0; goldenToiletPaper = 0
        itemLevels.removeAll(); activeAttacks.removeAll()
        UserDefaults.standard.removeObject(forKey: "SavedItemLevels")
        print("🧹 Hard Reset effectué")
    }

    private func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private static func saveItemLevels(_ levels: [String: Int]) {
        if let encoded = try? JSONEncoder().encode(levels) {
            UserDefaults.standard.set(encoded, forKey: "SavedItemLevels")
        }
    }

    private static func loadItemLevels() -> [String: Int] {
        if let data = UserDefaults.standard.data(forKey: "SavedItemLevels"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) { return decoded }
        return [:]
    }

    // MARK: - SYSTEME DE NOTIFICATIONS DYNAMIQUES
    var currentActe: Int {
        guard let actes = cloudManager?.actesInfo else { return 1 }
        return actes.keys.filter { isActeUnlocked($0) }.max() ?? 1
    }

    func checkNotifications() {
        guard let cloud = cloudManager else { return }
        let shownNotifs = UserDefaults.standard.stringArray(forKey: "shown_notifications") ?? []

        for notif in cloud.remoteNotifications {
            if shownNotifs.contains(notif.id) { continue }

            var shouldTrigger = false

            switch notif.conditionType {
            case "direct":
                shouldTrigger = true
            case "acte_reached":
                if let acteReq = Int(notif.conditionValue), currentActe >= acteReq { shouldTrigger = true }
            case "pps_reached":
                if let ppsReq = Double(notif.conditionValue), petsPerSecond >= ppsReq { shouldTrigger = true }
            case "score_reached":
                if let scoreReq = Int(notif.conditionValue), totalFartCount >= scoreReq { shouldTrigger = true }
            case "item_bought":
                if itemLevels[notif.conditionValue, default: 0] > 0 { shouldTrigger = true }
            case "count_production":
                if let req = Int(notif.conditionValue), countItems(in: .production) >= req { shouldTrigger = true }
            case "count_outil":
                if let req = Int(notif.conditionValue), countItems(in: .outil) >= req { shouldTrigger = true }
            case "count_amelioration":
                if let req = Int(notif.conditionValue), countItems(in: .amelioration) >= req { shouldTrigger = true }
            case "count_perturbateur":
                if let req = Int(notif.conditionValue), countItems(in: .perturbateur) >= req { shouldTrigger = true }
            case "count_defense":
                if let req = Int(notif.conditionValue), countItems(in: .defense) >= req { shouldTrigger = true }
            case "count_kado":
                if let req = Int(notif.conditionValue), countItems(in: .kado) >= req { shouldTrigger = true }
            case "count_skin":
                if let req = Int(notif.conditionValue), countItems(in: .skin) >= req { shouldTrigger = true }
            case "count_sound":
                if let req = Int(notif.conditionValue), countItems(in: .sound) >= req { shouldTrigger = true }
            case "count_background":
                if let req = Int(notif.conditionValue), countItems(in: .background) >= req { shouldTrigger = true }
            case "count_jalon":
                if let req = Int(notif.conditionValue), countItems(in: .jalonNarratif) >= req { shouldTrigger = true }
            default: break
            }

            if shouldTrigger {
                triggerAppNotification(notif)
            }
        }
    }
    
    private func countItems(in category: ItemCategory) -> Int {
        guard let items = cloudManager?.allItems else { return 0 }
        let categoryItemNames = items.filter { $0.category == category }.map { $0.name }
        let total = itemLevels.filter { categoryItemNames.contains($0.key) }.values.reduce(0, +)
        return total
    }
    
    private func triggerAppNotification(_ notif: GameNotification) {
        var shownNotifs = UserDefaults.standard.stringArray(forKey: "shown_notifications") ?? []
        shownNotifs.append(notif.id)
        UserDefaults.standard.set(shownNotifs, forKey: "shown_notifications")

        DispatchQueue.main.async {
            self.pendingNotification = notif
            self.showNotificationOverlay = true
        }
    }
}
