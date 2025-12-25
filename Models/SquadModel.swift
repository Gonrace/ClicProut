import Foundation

struct Squad: Identifiable, Codable {
    var id: String
    var name: String
    var leaderID: String
    var members: [String: String]      // [UserID: Username]
    var lastSeen: [String: Double]     // [UserID: Timestamp de dernière activité]
    var lastActivity: TimeInterval     // Activité globale de l'escouade
    var activeSessions: [String: Bool]? // [UserID: true] si connecté
    
    // Bonus automatique : +5% de production par membre dans l'équipe
    var squadPPSMultiplier: Double {
        return 1.0 + (Double(members.count) * 0.05)
    }
    
    // Retourne la liste des IDs membres actuellement en ligne
    var onlineMemberIDs: [String] {
        let now = Date().timeIntervalSince1970
        return lastSeen.filter { (id, timestamp) in
            (now - timestamp) < 300 // 5 minutes
        }.map { $0.key }
    }
}

struct SquadMessage: Identifiable, Codable {
    var id: String = UUID().uuidString
    var senderID: String
    var senderName: String
    var text: String
    var timestamp: TimeInterval
}
