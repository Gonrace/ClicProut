import Foundation
import FirebaseDatabase

// STRUCTURE POUR LES ATTAQUES
struct RemoteAttack: Codable {
    let attackID: String
    let senderUsername: String
    let timestamp: Date
    let durationMinutes: Int
}

// STRUCTURE POUR LES CADEAUX
struct RemoteGift: Codable {
    let giftID: String
    let senderName: String
    let timestamp: Date
}

// HELPER POUR CONVERTIR EN DICTIONNAIRE FIREBASE
extension Encodable {
    func toDictionary() -> [String: Any]? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970 // Format Date compatible Firebase
        guard let data = try? encoder.encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any]
    }
}
