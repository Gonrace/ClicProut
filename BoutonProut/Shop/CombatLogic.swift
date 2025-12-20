import Foundation

struct CombatLogic {
    // Cette variable sera remplie par le CSVLoader dans GameData
    static var defensesForAttack: [String: [String]] = [:]

    static func canDefend(attackID: String, defenseID: String) -> Bool {
        guard let validDefenses = defensesForAttack[attackID] else { return false }
        return validDefenses.contains(defenseID)
    }
}
