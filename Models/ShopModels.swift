import Foundation

enum CurrencyType: String, Codable {
    case pets = "pets"
    case goldenPaper = "goldenPaper"
}

enum ItemCategory: String, Codable {
    case production = "production"
    case outil = "outil"
    case amelioration = "amelioration"
    case jalonNarratif = "jalonNarratif"
    case defense = "defense"
    case perturbateur = "perturbateur"
    case skin = "skin"
    case sound = "sound"
    case background = "background"
    case kado = "kado"
}

struct ShopItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    let category: ItemCategory
    let acte: Int
    let baseCost: Int
    let currency: CurrencyType
    
    // Stats
    var dpsRate: Double = 0.0          // PPS_Rate
    var clickMultiplier: Int = 0       // PPC_Bonus
    
    // Combat (Indices 7 à 10 du CSV)
    var multPPS: Double = 1.0
    var multPPC: Double = 1.0
    var lossRate: Double = 0.0
    var durationSec: Int = 0
    
    let emoji: String
    let description: String
    
    var requiredItem: String? = nil
    var requiredItemCount: Int? = nil
    var effectID: String? = nil
    
    var isConsumable: Bool {
        return category == .perturbateur || category == .defense
    }

    // Helper pour le GameManager
    var durationMinutes: Int {
        return durationSec > 0 ? max(1, durationSec / 60) : 0
    }
}

struct ActeMetadata: Codable {
    let id: Int
    let title: String
    let description: String
    let threshold: Double
}
