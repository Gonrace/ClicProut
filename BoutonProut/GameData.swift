import SwiftUI
import Combine

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
        return standardShopItems + cosmeticShopItems
    }
    
    // --- LOGIQUE DE CALCUL ---
    
    var prestigeMultiplier: Double { 1.0 }
    
    // Calcul PPS (Mise à jour pour la nouvelle structure)
    var petsPerSecond: Double {
        var totalDPS: Double = 0
        var globalDPSMultiplier: Double = 1.0
        
        // 1. Calcul des multiplicateurs globaux de PPS (Upgrades)
        if itemLevels["Tuyauterie XXL", default: 0] > 0 { globalDPSMultiplier *= 1.02 }
        if itemLevels["Filtre à Gaz", default: 0] > 0 { globalDPSMultiplier *= 1.05 }
        if itemLevels["Climatiseur", default: 0] > 0 { globalDPSMultiplier *= 1.10 }
        if itemLevels["Câblage Optique", default: 0] > 0 { globalDPSMultiplier *= 1.15 }

        // 2. Calcul des bâtiments
        for item in standardShopItems.filter({ $0.category == .production }) { // Filtre sur la category
            let count = itemLevels[item.name, default: 0]
            if count == 0 { continue }
            
            var itemDPS = Double(count) * (item.dpsRate / 10.0)
            
            // 3. Vérifier les améliorations spécifiques
            if let upgrade = standardShopItems.first(where: { $0.category == .amelioration && $0.requiredItem == item.name }) {
                if itemLevels[upgrade.name, default: 0] > 0 {
                    // Logique simplifiée : double ou triple la production
                    if upgrade.name.contains("Triple") || upgrade.name.contains("Cage") || upgrade.name.contains("Engrais") || upgrade.name.contains("Épices") {
                        itemDPS *= 3.0
                    } else { // double pour les autres
                        itemDPS *= 2.0
                    }
                }
            }
            
            totalDPS += itemDPS
        }
        
        // VÉRIFICATION D'ATTAQUE (NOUVEAU)
        if activeAttacks.keys.contains("attack_dps_reduction_50") {
                // Si l'attaque est en cours, réduire le DPS global.
                globalDPSMultiplier *= 0.5
        }
        
        // 4. Application des multiplicateurs globaux
        return totalDPS * globalDPSMultiplier
    }
    
    // Calcul Puissance Clic (Mise à jour pour la nouvelle structure)
    var clickPower: Int {
        var power: Double = 1.0
        var globalPPCMultiplier: Double = 1.0
        
        // 1. Calcul des bonus d'objets (PPC de base)
        for item in standardShopItems.filter({ $0.category == .outil }) {
            let count = itemLevels[item.name, default: 0]
            power += Double(count * item.clickMultiplier)
        }
        
        // 2. Calcul des multiplicateurs globaux de PPC (Upgrades)
        if itemLevels["Double Culotte", default: 0] > 0 { globalPPCMultiplier *= 2.0 }
        if itemLevels["Peau de Vache", default: 0] > 0 { globalPPCMultiplier *= 1.02 }
        if itemLevels["Vernis à Ongles", default: 0] > 0 { globalPPCMultiplier *= 1.05 }
        if itemLevels["Gant de Pêche", default: 0] > 0 { globalPPCMultiplier *= 1.10 }
        if itemLevels["Siège Ergonomique", default: 0] > 0 { globalPPCMultiplier *= 1.15 }

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
        
        // 1. Calcul du Coût (utilisé aussi dans ShopView)
        let cost: Int
        if item.currency == .goldenPaper || item.category == .amelioration {
            cost = item.baseCost // Prix fixe
        } else {
            cost = Int(Double(item.baseCost) * pow(1.2, Double(level))) // Prix progressif
        }
        
        // 2. Vérifications de disponibilité (Achat unique et prérequis)
        if (item.currency == .goldenPaper || item.category == .amelioration) && level > 0 { return false }
        if let req = item.requiredItem, let reqCount = item.requiredItemCount {
            if itemLevels[req, default: 0] < reqCount { return false }
        }
        
        // 3. Vérification Solde et Dépense
        if item.currency == .pets {
            if totalFartCount < cost { return false }
            totalFartCount -= cost // Dépense Pets
        } else { // Golden Paper
            if goldenToiletPaper < cost { return false }
            goldenToiletPaper -= cost // Dépense PQ
        }
        
        // 4. Succès: Augmenter le niveau
        if item.isConsumable {
            // Si c'est un Perturbateur consommable (à implémenter via un compteur si vous le gérez en stock)
            // Pour l'instant, nous considérons la plupart des Perturbateurs comme des achats uniques d'accès.
        } else {
            itemLevels[item.name, default: 0] += 1
        }
        
        // NOUVEAU : Si c'est un Bâtiment (auto-peteur), déclencher le signal.
        if item.category == .production {
            autoFarterUpdateCount += 1
        }

        return true
    }
    
    // NOUVEAU : Fonction pour appliquer une attaque (appelée par GameManager)
    func applyAttack(effectID: String, duration: Int) -> Bool {
        // 1. Vérifier la défense avant d'appliquer
        if checkDefense(against: effectID) {
            return false // Attaque bloquée
        }
            
        // 2. Appliquer l'attaque
        let endTime = Date().addingTimeInterval(TimeInterval(duration * 60))
            activeAttacks[effectID] = endTime
        return true
    }
        
    // NOUVEAU : Fonction pour vérifier les défenses (utilisée dans applyAttack et pour les événements PvE)
    func checkDefense(against attackID: String) -> Bool {
        // Vérifie si l'utilisateur possède l'objet de défense correspondant.
        
        // Exemple 1 : Défense contre le Pet Foireux (PvE)
        if attackID == "event_pet_foireux" && itemLevels["Smecta", default: 0] > 0 {
            return true
        }
        // Exemple 2 : Défense contre le Spray Désodorisant (PvP)
        if attackID == "attack_dps_reduction_50" && itemLevels["Bouchon de Fesses", default: 0] > 0 {
            return true
        }
        
        // Ajoutez ici toute la logique de défense basée sur itemLevels
        return false
    }
    
    // VRAI RESET (Pour les tests ou recommencer à zéro zéro)
    func hardReset() {
        totalFartCount = 0
        lifetimeFarts = 0
        goldenToiletPaper = 0 // Réinitialisation de la monnaie premium
        itemLevels = [:]
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
    // --- NOUVELLES FONCTIONS DE DÉBOGAGE ---

    /// Ajoute une grande quantité de Pets pour le test.
    func addCheatPets() {
        // Ajout de 1 milliard de pets pour couvrir tous les tiers rapidement.
        self.totalFartCount += 1_000_000_000
        self.lifetimeFarts += 1_000_000_000
    }
        
    /// Ajoute une grande quantité de PQ d'Or pour le test des cosmétiques.
    func addCheatGoldenPaper() {
        self.goldenToiletPaper += 999
    }
        
    /// Réinitialise l'état du jeu au niveau 0 (utile pour le test)
    func softReset() {
        self.totalFartCount = 0
        self.lifetimeFarts = 0
        self.goldenToiletPaper = 0
        self.itemLevels = [:] // Réinitialise l'inventaire
        self.activeAttacks = [:] // Réinitialise les attaques subies
        // Invalider le timer PPS dans ContentView après cet appel !
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
