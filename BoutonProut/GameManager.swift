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
    
    // ID anonyme de l'utilisateur (persistant via UserDefaults)
    var userID: String {
        if let id = UserDefaults.standard.string(forKey: "userID") {
            return id
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: "userID")
        return newID
    }
    
    // Nom d'utilisateur (modifiable et observé par les vues)
    @Published var username: String = "Inconnu"
    
    // Référence à la racine du classement dans Firebase (initialisée dans init)
    private let databaseRef: DatabaseReference
    
    // Les données du classement que la vue affichera
    @Published var leaderboard: [LeaderboardEntry] = []
    
    // Initialisation pour charger l'ID, le nom ET configurer la DB
    init() {
        // Configuration de la base de données avec l'URL de la région spécifique (CORRECTION DE L'ERREUR DE RÉGION)
        self.databaseRef = Database.database(url: FIREBASE_DATABASE_URL).reference().child("leaderboard")
        
        // Assure que l'userID est généré/chargé au démarrage
        _ = self.userID
        
        // Charger le nom stocké, ou générer un nom aléatoire si nouveau joueur
        if let savedUsername = UserDefaults.standard.string(forKey: "username") {
            self.username = savedUsername
        } else {
            // Nom par défaut lors du premier lancement
            let newUsername = "Prouteur Anonyme \(Int.random(in: 1000...9999))"
            self.username = newUsername
            UserDefaults.standard.set(newUsername, forKey: "username")
        }
    }
    
    /**
     Met à jour le nom d'utilisateur et sauvegarde immédiatement le score actuel
     pour mettre à jour le classement Firebase avec le nouveau nom.
     */
    func saveNewUsername(_ newName: String, currentScore: Int) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // 1. Sauvegarde locale du nouveau nom
        UserDefaults.standard.set(trimmedName, forKey: "username")
        
        // 2. Mise à jour de la variable Observable
        self.username = trimmedName
        
        // 3. Mise à jour du classement avec le nouveau nom et le score actuel
        self.saveScore(score: currentScore)
    }

    // Fonction pour sauvegarder le score (appellée par ContentView)
    func saveScore(score: Int) {
        let entry: [String: Any] = [
            "username": self.username,
            "score": score
        ]
        
        // Sauvegarde le score sous l'ID unique de l'utilisateur
        databaseRef.child(userID).setValue(entry) { error, _ in
            if let error = error {
                print("Erreur Firebase: Échec de la sauvegarde du score: \(error.localizedDescription)")
            }
        }
    }
    
    // Fonction pour charger le classement depuis Firebase
    func fetchLeaderboard() {
        // queryOrdered(byChild: "score") et queryLimited(toLast: 100) sont utilisés ici
        databaseRef.queryOrdered(byChild: "score").queryLimited(toLast: 100).observeSingleEvent(of: .value) { snapshot in
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
            
            self.leaderboard = fetchedEntries.sorted { $0.score > $1.score }
            
        } withCancel: { error in
            print("Erreur Firebase: Échec de la lecture du classement: \(error.localizedDescription)")
        }
    }
}
