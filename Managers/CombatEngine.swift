import Foundation

struct CombatEngine {
    static func getActiveMultipliers(attacks: [String: ActiveAttackInfo]) -> (pps: Double, ppc: Double) {
        var multPPS = 1.0
        var multPPC = 1.0
        let now = Date()
        for attack in attacks.values where attack.expiryDate > now {
            multPPS *= attack.multPPS
            multPPC *= attack.multPPC
        }
        return (multPPS, multPPC)
    }

    static func isActeUnlocked(acte: Int, items: [ShopItem], levels: [String: Int], threshold: Double) -> Bool {
        if acte <= 1 { return true }
        let itemsPrecedent = items.filter { $0.acte == acte - 1 && ($0.category == .production || $0.category == .outil) }
        if itemsPrecedent.isEmpty { return false }
        let owned = itemsPrecedent.filter { levels[$0.name, default: 0] > 0 }
        return Double(owned.count) / Double(itemsPrecedent.count) >= threshold
    }
}
