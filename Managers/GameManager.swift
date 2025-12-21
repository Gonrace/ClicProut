import Foundation
import FirebaseDatabase
import Combine

// URL de la base de données Firebase
let FIREBASE_DATABASE_URL = "https://clicprout-default-rtdb.europe-west1.firebasedatabase.app"

// MARK: - STRUCTURES DE DONNÉES
struct LeaderboardEntry: Identifiable, Decodable {
    let id: String
    let username: String
    let score: Int
}

class GameManager: ObservableObject {
    
    // Références Firebase
    private let db = Database.database(url: FIREBASE_DATABASE_URL).reference()
    private let leaderboardRef: DatabaseReference
    
    @Published var username: String = "Inconnu"
    @Published var leaderboard: [LeaderboardEntry] = []
    
    private var leaderboardHandle: DatabaseHandle?
    private var attacksHandle: DatabaseHandle?
    
    var userID: String {
        if let id = UserDefaults.standard.string(forKey: "userID") {
            return id
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: "userID")
        return newID
    }
    
    init() {
        self.leaderboardRef = db.child("leaderboard")
        
        if let savedUsername = UserDefaults.standard.string(forKey: "username") {
            self.username = savedUsername
        } else {
            let newUsername = "Prouteur Anonyme \(Int.random(in: 1000...9999))"
            self.username = newUsername
            UserDefaults.standard.set(newUsername, forKey: "username")
        }
    }
    
    deinit {
        stopObservingLeaderboard()
    }
    
    // MARK: - GESTION DU PROFIL
    
    func saveNewUsername(_ newName: String, lifetimeScore: Int) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        UserDefaults.standard.set(trimmedName, forKey: "username")
        self.username = trimmedName
        self.saveLifetimeScore(lifetimeScore: lifetimeScore)
    }
    
    func saveLifetimeScore(lifetimeScore: Int) {
        let entry: [String: Any] = [
            "username": self.username,
            "score": lifetimeScore
        ]
        leaderboardRef.child(userID).setValue(entry)
    }
    
    // MARK: - LOGIQUE DU CLASSEMENT
    
    func startObservingLeaderboard() {
        stopObservingLeaderboard()
        let query = leaderboardRef.queryOrdered(byChild: "score").queryLimited(toLast: 100)
        
        leaderboardHandle = query.observe(.value) { snapshot in
            var fetchedEntries: [LeaderboardEntry] = []
            guard let value = snapshot.value as? [String: [String: Any]] else {
                DispatchQueue.main.async { self.leaderboard = [] }
                return
            }
            for (id, data) in value {
                if let username = data["username"] as? String, let score = data["score"] as? Int {
                    fetchedEntries.append(LeaderboardEntry(id: id, username: username, score: score))
                }
            }
            DispatchQueue.main.async {
                self.leaderboard = fetchedEntries.sorted { $0.score > $1.score }
            }
        }
    }
    
    func stopObservingLeaderboard() {
        if let handle = leaderboardHandle {
            leaderboardRef.removeObserver(withHandle: handle)
            leaderboardHandle = nil
        }
    }
}
    
