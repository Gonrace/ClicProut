// Fichier: AttackModels.swift (NOUVEAU)

import Foundation

// Structure pour les attaques dans la base de données Firebase
struct RemoteAttack: Codable {
    let attackID: String          // L'EffectID de l'objet Perturbateur (ex: "attack_dps_reduction_50")
    let senderUsername: String    // Nom de celui qui a envoyé l'attaque
    let timestamp: Date           // Moment de l'envoi
    let durationMinutes: Int      // Durée de l'effet
}

// Helper pour sérialiser l'objet Codable en [String: Any] pour Firebase
extension Encodable {
    func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}
