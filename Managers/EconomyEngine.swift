import Foundation

struct EconomyEngine {
    /// Calcule le prix dynamique d'un objet selon son niveau
    static func calculateCost(baseCost: Int, level: Int, multiplier: Double) -> Int {
        return Int((Double(baseCost) * pow(multiplier, Double(level))).rounded())
    }
    
    /// Calcule le PPS de base (sans multiplicateurs de combat ni son)
    static func calculateBasePPS(items: [ShopItem], levels: [String: Int]) -> Double {
        var totalPPS: Double = 0
        let productions = items.filter { $0.category == .production }
        
        for item in productions {
            let count = levels[item.name, default: 0]
            if count > 0 {
                var itemPPS = Double(count) * item.dpsRate
                // Appliquer les améliorations spécifiques
                let upgrades = items.filter { $0.category == .amelioration && $0.requiredItem == item.name }
                for upgrade in upgrades where levels[upgrade.name, default: 0] > 0 {
                    itemPPS *= upgrade.dpsRate
                }
                totalPPS += itemPPS
            }
        }
        return totalPPS
    }
    
    /// Calcule la puissance de clic de base
    static func calculateBasePPC(items: [ShopItem], levels: [String: Int], baseValue: Int) -> Double {
        var power = Double(baseValue)
        let outils = items.filter { $0.category == .outil }
        
        for item in outils {
            let count = levels[item.name, default: 0]
            power += Double(count * item.clickMultiplier)
        }
        return power
    }
}
