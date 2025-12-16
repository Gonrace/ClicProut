import SwiftUI
import Combine
import Foundation // Nécessaire pour Date, TimeInterval, et JSONEncoder/Decoder

// NOTE: Nécessite ShopModels.swift, ShopList_Standard.swift, ShopList_Cosmetics.swift

class GameData: ObservableObject {
    
    // --- MONNAIES ET COMPTEURS ---
    @AppStorage("TotalFartCount") var totalFartCount: Int = 0
    @AppStorage("LifetimeFarts") var lifetimeFarts: Int = 0
    @AppStorage("GoldenToiletPaper") var goldenToiletPaper: Int = 0 // Monnaie Premium
    
    // Signal pour l'animation (Compteur d'événements)
    @Published var autoFarterUpdateCount: Int = 0
    
    // État des attaques subies (ID de l'effet : Date de fin)
    @Published var activeAttacks: [String: Date] = [:]
    
    // Niveaux des objets (Sauvegardés)
    @Published var itemLevels: [String: Int] = loadItemLevels() {
        didSet { saveItemLevels(itemLevels) }
    }
    
    // Combine les deux listes de la boutique pour les calculs globaux
    var allItems: [ShopItem] {
        // Assurez-vous que ShopList_Cosmetics.swift existe
        return standardShopItems + cosmeticShopItems
    }
    
    // --- LOGIQUE DE CALCUL ---
    
    var prestigeMultiplier: Double { 1.0 }
    
    // Calcul PPS
    var petsPerSecond: Double {
        var totalDPS: Double = 0
        var globalDPSMultiplier: Double = 1.0
        
        // 1. Calcul des multiplicateurs globaux de PPS (Upgrades)
        // NOTE: Si vous avez une liste d'Upgrades pour les multiplicateurs globaux, utilisez la
        // pour simplifier au lieu de lister les noms en dur.
        if itemLevels["Tuyauterie XXL", default: 0] > 0 { globalDPSMultiplier *= 1.05 }
        if itemLevels["Climatisation", default: 0] > 0 { globalDPSMultiplier *= 1.10 }
        
        // 2. Calcul des bâtiments
        for item in standardShopItems.filter({ $0.category == .production }) {
            let count = itemLevels[item.name, default: 0]
            if count == 0 { continue }
            
            var itemDPS = Double(count) * (item.dpsRate / 10.0)
            
            // 3. Vérifier les améliorations spécifiques (Logique inchangée)
            if let upgrade = standardShopItems.first(where: { $0.category == .amelioration && $0.requiredItem == item.name }) {
                if itemLevels[upgrade.name, default: 0] > 0 {
                    // Logique simplifiée : double ou triple la production
                    if upgrade.name.contains("Triple") { // Exemple de logique de triple
                        itemDPS *= 3.0
                    } else if upgrade.name.contains("Sauce Piquante") { // Exemple de double
                        itemDPS *= 2.0
                    }
                    // TO DO: Ajouter la logique pour Héritage (x5 T1) ici si nécessaire.
                }
            }
            
            totalDPS += itemDPS
        }
        
        // 4. VÉRIFICATION D'ATTAQUE (PvP)
        // Vérifie si l'effet de malus est actif (date de fin future)
        if let endTime = activeAttacks["attack_dps_reduction_50"], Date() < endTime {
            // L'attaque est active : réduire le DPS global.
            globalDPSMultiplier *= 0.5
        } else if let endTime = activeAttacks["attack_dps_reduction_50"], Date() >= endTime {
            // L'attaque est terminée : la retirer
            activeAttacks.removeValue(forKey: "attack_dps_reduction_50")
        }
        
        // 5. Application des multiplicateurs globaux
        return totalDPS * globalDPSMultiplier * prestigeMultiplier
    }
    
    // Calcul Puissance Clic (Logique inchangée, elle est OK)
    var clickPower: Int {
        var power: Double = 1.0
        var globalPPCMultiplier: Double = 1.0
        
        // 1. Calcul des bonus d'objets (PPC de base)
        for item in standardShopItems.filter({ $0.category == .outil }) {
            let count = itemLevels[item.name, default: 0]
            power += Double(count * item.clickMultiplier)
        }
        
        // 2. Calcul des multiplicateurs globaux de PPC (Upgrades)
        if itemLevels["Double Clic", default: 0] > 0 { globalPPCMultiplier *= 2.0 }
        // ... (Autres multiplicateurs PPC) ...
        
        // 3. Application du multiplicateur global
        power *= globalPPCMultiplier
        
        return Int(power.rounded())
    }
    
    var calculatedPoopScale: CGFloat {
        let baseSize: CGFloat = 1.0
        let growthFactor = CGFloat(totalFartCount) / 1000.0
        return min(baseSize + growthFactor, 3.5)
    }

    // --- LOGIQUE D'ACHAT CENTRALISÉE ---
    func attemptPurchase(item: ShopItem) -> Bool {
        let level = itemLevels[item.name, default: 0]
        
        // Détecte les achats qui sont uniques (Niveau max 1, coûte fixe)
        let isSingleLevelItem = (
            item.category == .amelioration ||
            item.category == .defense ||
            item.category == .jalonNarratif ||
            item.category == .perturbateur ||
            item.category.rawValue.contains("Cosmétique")
        )
        
        // 1. Calcul du Coût
        let cost: Int
        if item.category == .production || item.category == .outil {
            cost = Int(Double(item.baseCost) * pow(1.2, Double(level))) // Progressif
        } else {
            cost = item.baseCost // Fixe (si isSingleLevelItem est vrai)
        }
        
        // 2. Vérifications de disponibilité
        
        // BUG FIX: Bloquer l'achat si c'est unique ET déjà possédé (level > 0).
        // Si isConsumable = false (cas des perturbateurs pour le flow PvP), on ne peut acheter qu'une fois.
        if isSingleLevelItem && !item.isConsumable && level > 0 {
            return false
        }
        
        if let req = item.requiredItem, let reqCount = item.requiredItemCount {
            if itemLevels[req, default: 0] < reqCount { return false }
        }
        
        // 3. Vérification Solde et Dépense
        if item.currency == .pets {
            if totalFartCount < cost { return false }
            totalFartCount -= cost
        } else { // Golden Paper
            if goldenToiletPaper < cost { return false }
            goldenToiletPaper -= cost
        }
        
        // 4. Succès: Augmenter le niveau
        if isSingleLevelItem {
            // Pour tous les achats uniques (Amélioration, Défense, Perturbateur, Jalon, Cosmétique), forcer le niveau à 1.
            itemLevels[item.name] = 1
        } else {
            // Production/Outil: Incrémenter normalement
            itemLevels[item.name, default: 0] += 1
        }
        
        // Déclenchement de l'animation si Bâtiment acheté
        if item.category == .production {
            autoFarterUpdateCount += 1
        }

        return true
    }
    
    // --- LOGIQUE PVP ET DÉFENSE (Phase 2) ---

    /// Applique un effet d'attaque reçu via Firebase.
    func applyAttack(effectID: String, duration: Int) -> Bool {
        
        // 1. Vérifier la défense avant d'appliquer
        if checkDefense(against: effectID) {
            return false // Attaque bloquée
        }
        
        // 2. Appliquer l'effet
        // Gérer les effets immédiats (vol/destruction) et les effets de durée.
        switch effectID {
        case "attack_dps_reduction_50":
            let endTime = Date().addingTimeInterval(TimeInterval(duration * 60))
            activeAttacks[effectID] = endTime
            return true
        
        case "attack_loss_t1_10":
            // Logique de destruction de 10% des bâtiments T1 (Haricot)
            if let haricotItem = standardShopItems.first(where: { $0.name == "Haricot" }) {
                let currentLevel = itemLevels["Haricot", default: 0]
                let loss = Int(Double(currentLevel) * 0.10)
                itemLevels["Haricot"] = max(0, currentLevel - loss)
                // Redémarrer le timer si la perte est significative
                autoFarterUpdateCount += 1
                return true
            }
            return false
            
        default:
            return false
        }
    }
        
    /// Fonction pour vérifier les défenses (utilisée dans applyAttack)
    func checkDefense(against attackID: String) -> Bool {
        
        if attackID == "attack_dps_reduction_50" && itemLevels["Bouchon de Fesses", default: 0] > 0 {
            return true // Protège contre le Spray Désodorisant
        }
        if attackID == "attack_loss_t1_10" && itemLevels["Smecta", default: 0] > 0 {
            return true // Protège contre le Pet Foireux (même si Smecta est censé être PvE, on le réutilise pour la démo)
        }
        
        return false
    }
    
    // --- FONCTIONS DE RESET ET DEBUG ---
    
    // VRAI RESET (Pour les tests ou recommencer à zéro zéro)
    func hardReset() {
        totalFartCount = 0
        lifetimeFarts = 0
        goldenToiletPaper = 0
        itemLevels = [:]
        activeAttacks = [:]
    }
    
    /// Réinitialise l'état du jeu au niveau 0 (utilisé par le bouton DEV)
    func softReset() {
        self.totalFartCount = 0
        self.lifetimeFarts = 0
        self.goldenToiletPaper = 0
        self.itemLevels = [:]
        self.activeAttacks = [:]
    }

    /// Ajoute une grande quantité de Pets pour le test.
    func addCheatPets() {
        self.totalFartCount += 1_000_000_000
        self.lifetimeFarts += 1_000_000_000
    }
        
    /// Ajoute une grande quantité de PQ d'Or pour le test des cosmétiques.
    func addCheatGoldenPaper() {
        self.goldenToiletPaper += 999
    }
    
    // Helper pour l'affichage (Utilisé pour la petite barre d'inventaire dans ContentView)
    var ownedItemsDisplay: [String] {
        return allItems
            // NOUVEAU FILTRE : ON MONTRE SEULEMENT LES OUTILS DE CLIC
            .filter { $0.category == .outil }
            .compactMap { item in
                let value = itemLevels[item.name, default: 0]
                if value > 0 {
                    // On affiche seulement l'emoji et le niveau/compte
                    return "\(item.emoji) \(value)"
                }
                return nil // Ignore les objets non possédés ou non cliquables
        }
    }
}

// --- PERSISTANCE ---
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
