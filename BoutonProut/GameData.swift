import SwiftUI
import Combine
import Foundation

// NOTE: Ce fichier gère l'état global du jeu, l'économie et la logique de combat.
// Nécessite : ShopModels.swift, ShopList_Standard.swift, ShopList_Cosmetics.swift

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
    @Published var itemLevels: [String: Int] = loadItemLevels() {
        didSet { saveItemLevels(itemLevels) }
    }
    
    var allItems: [ShopItem] {
        return standardShopItems + cosmeticShopItems
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
                    if upgrade.name.contains("Triple") { itemDPS *= 3.0 }
                    else if upgrade.name.contains("Sauce Piquante") { itemDPS *= 2.0 }
                }
            }
            totalDPS += itemDPS
        }
        
        // 4. NETTOYAGE ET APPLICATION DES MALUS PvP
        let now = Date()
        for (effectID, expiryDate) in activeAttacks {
            if now >= expiryDate {
                // L'attaque est finie, on nettoie
                DispatchQueue.main.async {
                    self.activeAttacks.removeValue(forKey: effectID)
                }
            } else if effectID == "attack_dps_reduction_50" {
                // Réduction de 50% du PPS global
                globalDPSMultiplier *= 0.5
            }
        }
        
        return totalDPS * globalDPSMultiplier * prestigeMultiplier
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
        
        return Int(power * globalPPCMultiplier)
    }
    
    var calculatedPoopScale: CGFloat {
        let baseSize: CGFloat = 1.0
        let growthFactor = CGFloat(totalFartCount) / 5000.0
        return min(baseSize + growthFactor, 2.5)
    }

    // MARK: - MOTEUR D'ACHAT
    
    func attemptPurchase(item: ShopItem) -> Bool {
        let level = itemLevels[item.name, default: 0]
        
        let isSingleLevelItem = (
            item.category == .amelioration ||
            item.category == .defense ||
            item.category == .jalonNarratif ||
            item.category == .perturbateur ||
            item.category == .skin ||
            item.category == .sound ||
            item.category == .background
        )
        
        let cost: Int
        if item.category == .production || item.category == .outil {
            cost = Int(Double(item.baseCost) * pow(1.2, Double(level)))
        } else {
            cost = item.baseCost
        }
        
        if isSingleLevelItem && !item.isConsumable && level > 0 { return false }
        
        if let req = item.requiredItem, let reqCount = item.requiredItemCount {
            if itemLevels[req, default: 0] < reqCount { return false }
        }
        
        if item.currency == .pets {
            guard totalFartCount >= cost else { return false }
            totalFartCount -= cost
        } else {
            guard goldenToiletPaper >= cost else { return false }
            goldenToiletPaper -= cost
        }
        
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
    
    // MARK: - SYSTÈME DE COMBAT
    
    func applyAttack(effectID: String, duration: Int, attackerName: String = "Inconnu", weaponName: String = "une attaque") -> Bool {
        if checkDefense(against: effectID) { return false }
        
        self.lastAttackerName = attackerName
        self.lastAttackWeapon = weaponName
        
        let expiryDate = Date().addingTimeInterval(TimeInterval(duration * 60))
        
        switch effectID {
        case "attack_dps_reduction_50":
            activeAttacks[effectID] = expiryDate
            return true
            
        case "attack_loss_t1_10":
            let currentLevel = itemLevels["Haricot", default: 0]
            let loss = Int(Double(currentLevel) * 0.10)
            itemLevels["Haricot"] = max(0, currentLevel - loss)
            return true
            
        default:
            return false
        }
    }
        
    func checkDefense(against attackID: String) -> Bool {
        if attackID == "attack_dps_reduction_50" && itemLevels["Bouchon de Fesses", default: 0] > 0 {
            return true
        }
        if attackID == "attack_loss_t1_10" && itemLevels["Smecta", default: 0] > 0 {
            return true
        }
        return false
    }
    
    // MARK: - DÉBOGAGE ET HELPERS
    
    /// Reset complet : Score actuel, Inventaire, Monnaie Premium et Score à vie.
    func hardReset() {
        // 1. Remise à zéro des variables en mémoire (Interface)
        self.totalFartCount = 0
        self.lifetimeFarts = 0
        self.goldenToiletPaper = 0
        self.itemLevels = [:]
        self.activeAttacks = [:]
        self.petAccumulator = 0.0
        
        // 2. Nettoyage forcé du stockage physique (UserDefaults)
        // Cela efface les données même si l'app crash juste après
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "TotalFartCount")
        defaults.removeObject(forKey: "LifetimeFarts")
        defaults.removeObject(forKey: "GoldenToiletPaper")
        defaults.removeObject(forKey: "SavedItemLevels")
        
        // Synchronisation pour s'assurer que c'est bien écrit sur le disque
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
}

// MARK: - PERSISTANCE
private func saveItemLevels(_ levels: [String: Int]) {
    if let encoded = try? JSONEncoder().encode(levels) {
        UserDefaults.standard.set(encoded, forKey: "SavedItemLevels")
    }
}

private func loadItemLevels() -> [String: Int] {
    if let data = UserDefaults.standard.data(forKey: "SavedItemLevels"),
       let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
        return decoded
    }
    return [:]
}
