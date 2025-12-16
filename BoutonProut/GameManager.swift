import Foundation
import FirebaseDatabase
import Combine

// Assurez-vous que cette URL correspond EXACTEMENT à celle de votre erreur/console Firebase !
let FIREBASE_DATABASE_URL = "https://clicprout-default-rtdb.europe-west1.firebasedatabase.app"

// Structure pour le classement
struct LeaderboardEntry: Identifiable, Decodable {
    let id: String
    let username: String
    let score: Int
}

class GameManager: ObservableObject {
    
    var userID: String {
        if let id = UserDefaults.standard.string(forKey: "userID") {
            return id
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: "userID")
        return newID
    }
    
    @Published var username: String = "Inconnu"
    
    private let databaseRef: DatabaseReference
    
    @Published var leaderboard: [LeaderboardEntry] = []
    
    // NOUVEAU : Handle pour l'observateur en temps réel
    private var leaderboardHandle: DatabaseHandle?
    
    init() {
        // Configuration de la base de données avec l'URL de la région spécifique
        self.databaseRef = Database.database(url: FIREBASE_DATABASE_URL).reference().child("leaderboard")
        
        _ = self.userID
        
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
    
    /**
     Met à jour le nom d'utilisateur et sauvegarde immédiatement le score actuel
     (qui est le lifetimeFarts).
     */
    func saveNewUsername(_ newName: String, lifetimeScore: Int) { // <-- MODIFIÉ
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        UserDefaults.standard.set(trimmedName, forKey: "username")
        self.username = trimmedName
        
        self.saveLifetimeScore(lifetimeScore: lifetimeScore) // Utilise la nouvelle fonction
    }

    // MODIFIÉ : Sauvegarde le score à vie pour le classement
    func saveLifetimeScore(lifetimeScore: Int) {
        let entry: [String: Any] = [
            "username": self.username,
            "score": lifetimeScore // <-- UTILISATION DU SCORE À VIE
        ]
        
        databaseRef.child(userID).setValue(entry) { error, _ in
            if let error = error {
                print("Erreur Firebase: Échec de la sauvegarde du score à vie: \(error.localizedDescription)")
            }
        }
    }
    
    // NOUVEAU : Fonction pour OBSERVER en temps réel
    func startObservingLeaderboard() {
        // S'assure d'arrêter toute observation existante
        stopObservingLeaderboard()
        
        let query = databaseRef.queryOrdered(byChild: "score").queryLimited(toLast: 100)
        
        // Utilise observe(.value) pour la mise à jour en temps réel
        leaderboardHandle = query.observe(.value) { snapshot in
            var fetchedEntries: [LeaderboardEntry] = []
            
            guard let value = snapshot.value as? [String: [String: Any]] else {
                self.leaderboard = []
                return
            }
            
            for (id, data) in value {
                if let username = data["username"] as? String,
                   let score = data["score"] as? Int {
                    fetchedEntries.append(LeaderboardEntry(id: id, username: username, score: score))
                }
            }
            
            // Tri descendant
            self.leaderboard = fetchedEntries.sorted { $0.score > $1.score }
            
        } withCancel: { error in
            print("Erreur Firebase: Échec de l'observation du classement: \(error.localizedDescription)")
        }
    }
    
    // NOUVEAU : Fonction pour arrêter l'observation (à l'extinction de la vue)
    func stopObservingLeaderboard() {
        if let handle = leaderboardHandle {
            databaseRef.removeObserver(withHandle: handle)
            leaderboardHandle = nil
        }
    }
}
