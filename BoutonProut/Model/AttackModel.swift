import Foundation

// MARK: - STRUCTURE POUR FIREBASE
struct RemoteAttack: Codable {
    let attackID: String          // L'ID technique (ex: atk_spray)
    let senderUsername: String    // Qui attaque
    let timestamp: Date           // Quand
    let durationMinutes: Int      // Combien de temps
}

// MARK: - EXTENSION HELPER
extension Encodable {
    /// Convertit n'importe quel objet Codable en dictionnaire pour Firebase
    func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any]
    }
}
