import SwiftUI
import Foundation
import Combine

// --- TYPE D'OBJET ---
enum ItemType: String, Codable {
    case building = "Bâtiment" // On peut en acheter l'infini
    case upgrade = "Amélioration" // On l'achète une seule fois
    case clicker = "Outil" // Pour le clic manuel
}

// --- DEFINITION DES OBJETS ---
struct ShopItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let baseCost: Int
    let dpsRate: Double          // Pets par 10s (Auto)
    let clickMultiplier: Int     // Bonus Clic
    let emoji: String
    let unlockThreshold: Int     // Palier de déblocage
    let type: ItemType           // Nouveau : Type d'objet
    let requiredItem: String?    // Nouveau : Si c'est une amélioration pour un objet précis
}

// --- LA GRANDE LISTE DE LA PROUTIQUE ---
let shopItems: [ShopItem] = [
    // --- TIERS 1 : BÂTIMENTS (AUTO) ---
    ShopItem(name: "Haricot Magique", description: "L'automatisation débute. 1 pet / 10s.", baseCost: 50, dpsRate: 1.0, clickMultiplier: 0, emoji: "🫘", unlockThreshold: 100, type: .building, requiredItem: nil),
    ShopItem(name: "Tonton Blagueur", description: "Tire sur mon doigt ! 5 pets / 10s.", baseCost: 150, dpsRate: 5.0, clickMultiplier: 0, emoji: "🤡", unlockThreshold: 200, type: .building, requiredItem: nil),
    ShopItem(name: "Bol de Chili", description: "Ça chauffe. 10 pets / 10s.", baseCost: 500, dpsRate: 10.0, clickMultiplier: 0, emoji: "🌶️", unlockThreshold: 500, type: .building, requiredItem: nil),
    ShopItem(name: "Cours de Yoga", description: "Relâchement total. 25 pets / 10s.", baseCost: 2000, dpsRate: 25.0, clickMultiplier: 0, emoji: "🧘", unlockThreshold: 2000, type: .building, requiredItem: nil),
    ShopItem(name: "Vache Laitière", description: "Méthane bio. 80 pets / 10s.", baseCost: 5000, dpsRate: 80.0, clickMultiplier: 0, emoji: "🐄", unlockThreshold: 5000, type: .building, requiredItem: nil),
    ShopItem(name: "Soupe aux Choux", description: "La Glaude approuve. 200 pets / 10s.", baseCost: 15000, dpsRate: 200.0, clickMultiplier: 0, emoji: "🍲", unlockThreshold: 10000, type: .building, requiredItem: nil),
    ShopItem(name: "Grand-mère Active", description: "L'expérience parle. 500 pets / 10s.", baseCost: 50000, dpsRate: 500.0, clickMultiplier: 0, emoji: "👵", unlockThreshold: 40000, type: .building, requiredItem: nil),
    ShopItem(name: "Usine de Cassoulet", description: "Production de masse. 2000 pets / 10s.", baseCost: 200000, dpsRate: 2000.0, clickMultiplier: 0, emoji: "🏭", unlockThreshold: 150000, type: .building, requiredItem: nil),
    ShopItem(name: "Compresseur à Gaz", description: "Industriel. 10k pets / 10s.", baseCost: 1000000, dpsRate: 10000.0, clickMultiplier: 0, emoji: "⚙️", unlockThreshold: 800000, type: .building, requiredItem: nil),
    ShopItem(name: "Vortex Temporel", description: "Pète hier et demain. 50k pets / 10s.", baseCost: 5000000, dpsRate: 50000.0, clickMultiplier: 0, emoji: "🌌", unlockThreshold: 4000000, type: .building, requiredItem: nil),
    ShopItem(name: "Big Bang Intestinal", description: "L'origine de l'univers. 1M pets / 10s.", baseCost: 50000000, dpsRate: 1000000.0, clickMultiplier: 0, emoji: "💥", unlockThreshold: 20000000, type: .building, requiredItem: nil),

    // --- TIERS 2 : CLIC (MANUEL) ---
    ShopItem(name: "Slip Aéré", description: "Confort de tir. +2 Clics.", baseCost: 300, dpsRate: 0.0, clickMultiplier: 2, emoji: "🩲", unlockThreshold: 0, type: .clicker, requiredItem: nil),
    ShopItem(name: "Siège de Course", description: "Stabilité. +5 Clics.", baseCost: 1200, dpsRate: 0.0, clickMultiplier: 5, emoji: "🏎️", unlockThreshold: 500, type: .clicker, requiredItem: nil),
    ShopItem(name: "Doigt Bionique", description: "Précision. +50 Clics.", baseCost: 25000, dpsRate: 0.0, clickMultiplier: 50, emoji: "🦾", unlockThreshold: 20000, type: .clicker, requiredItem: nil),

    // --- TIERS 3 : AMÉLIORATIONS (UPGRADES - Achat Unique) ---
    ShopItem(name: "Sauce Piquante", description: "Les haricots sont 2x plus efficaces.", baseCost: 1000, dpsRate: 0.0, clickMultiplier: 0, emoji: "🌶️", unlockThreshold: 500, type: .upgrade, requiredItem: "Haricot Magique"),
    ShopItem(name: "Livre de Blagues", description: "Tonton est 2x plus drôle (et efficace).", baseCost: 5000, dpsRate: 0.0, clickMultiplier: 0, emoji: "📖", unlockThreshold: 2000, type: .upgrade, requiredItem: "Tonton Blagueur"),
    ShopItem(name: "Double Culotte", description: "Les pets manuels sont doublés !", baseCost: 10000, dpsRate: 0.0, clickMultiplier: 0, emoji: "👖", unlockThreshold: 5000, type: .upgrade, requiredItem: nil)
]

// --- MODELE DE DONNEES ---
class GameData: ObservableObject {
    
    // Compteurs Principaux
    @AppStorage("TotalFartCount") var totalFartCount: Int = 0
    
    // Remplacement de lifetimeFarts par une version simple qui n'est qu'un stockage
    @AppStorage("LifetimeFarts") var lifetimeFarts: Int = 0
    
    // Inventaire
    @Published var autoFarterLevels: [String: Int] = loadAutoFarterLevels() {
        didSet { saveAutoFarterLevels(autoFarterLevels) }
    }
    
    // --- LOGIQUE DE CALCUL ---
    
    // Plus de multiplicateur de prestige
    var prestigeMultiplier: Double { 1.0 }
    
    // Calcul PPS (simplifié sans prestige multiplier)
    var petsPerSecond: Double {
        var totalDPS: Double = 0
        
        // 1. Calcul de base des bâtiments
        for item in shopItems.filter({ $0.type == .building }) {
            let count = autoFarterLevels[item.name, default: 0]
            var itemDPS = Double(count) * (item.dpsRate / 10.0)
            
            // Vérifier les améliorations (Upgrades)
            if let upgrade = shopItems.first(where: { $0.type == .upgrade && $0.requiredItem == item.name }) {
                if autoFarterLevels[upgrade.name, default: 0] > 0 {
                    itemDPS *= 2.0
                }
            }
            
            totalDPS += itemDPS
        }
        
        // Pas d'application de prestige multiplier
        return totalDPS
    }
    
    // Calcul Puissance Clic (simplifié sans prestige multiplier)
    var clickPower: Int {
        var power = 1
        
        // Bonus des objets clics
        for item in shopItems.filter({ $0.type == .clicker }) {
            let count = autoFarterLevels[item.name, default: 0]
            power += count * item.clickMultiplier
        }
        
        // Bonus Upgrade Global (Double Culotte)
        if autoFarterLevels["Double Culotte", default: 0] > 0 {
            power *= 2
        }
        
        // Pas d'application de prestige multiplier
        return power
    }
    
    var calculatedPoopScale: CGFloat {
        let baseSize: CGFloat = 1.0
        let growthFactor = CGFloat(totalFartCount) / 1000.0
        return min(baseSize + growthFactor, 3.5)
    }

    // --- LOGIQUE D'ADMIN ---
    
    // Suppression des fonctions de prestige
    
    // VRAI RESET (Pour les tests ou recommencer à zéro zéro)
    func hardReset() {
        totalFartCount = 0
        lifetimeFarts = 0
        autoFarterLevels = [:]
    }
    
    // Helper pour l'affichage
    var ownedItemsDisplay: [String] {
        return autoFarterLevels
            .filter { $0.value > 0 }
            .map { key, value in
                let emoji = shopItems.first(where: { $0.name == key })?.emoji ?? ""
                return "\(emoji) \(value)"
            }
    }
}

// --- SAUVEGARDE ---
private func saveAutoFarterLevels(_ levels: [String: Int]) {
    if let encoded = try? JSONEncoder().encode(levels) {
        UserDefaults.standard.set(encoded, forKey: "AutoFarterLevels")
    }
}

private func loadAutoFarterLevels() -> [String: Int] {
    if let savedData = UserDefaults.standard.data(forKey: "AutoFarterLevels"),
       let decodedLevels = try? JSONDecoder().decode([String: Int].self, from: savedData) {
        return decodedLevels
    }
    return [:]
}
