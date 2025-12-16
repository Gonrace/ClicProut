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
    
    // CORRECTION: La référence 'db' est maintenant la référence principale non modifiable
    private let db = Database.database().reference()
    private let databaseRef: DatabaseReference // Référence spécifique au classement

    // --- PROPRIÉTÉS PUBLIÉES ---
    @Published var username: String = "Inconnu"
    @Published var leaderboard: [LeaderboardEntry] = []
    
    // NOUVEAU : Handle pour les observateurs en temps réel
    private var leaderboardHandle: DatabaseHandle?
    private var attacksHandle: DatabaseHandle? // Handle pour l'observateur d'attaques
    
    // --- ID Utilisateur (Unique au joueur) ---
    var userID: String {
        if let id = UserDefaults.standard.string(forKey: "userID") {
            return id
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: "userID")
        return newID
    }
    
    // --- Initialisation ---
    init() {
        // CORRECTION: Utiliser l'URL spécifique pour la référence de base
        Database.database().reference(fromURL: FIREBASE_DATABASE_URL).observeSingleEvent(of: .value) { _ in }
        
        // La référence au classement
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
        stopObservingIncomingAttacks()
    }
    
    // --- FONCTIONS DE GESTION DU PROFIL ET DU CLASSEMENT (Inchagées) ---
    
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
        
        databaseRef.child(userID).setValue(entry) { error, _ in
            if let error = error {
                print("Erreur Firebase: Échec de la sauvegarde du score à vie: \(error.localizedDescription)")
            }
        }
    }
    
    func startObservingLeaderboard() {
        stopObservingLeaderboard()
        
        let query = databaseRef.queryOrdered(byChild: "score").queryLimited(toLast: 100)
        
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
            
            self.leaderboard = fetchedEntries.sorted { $0.score > $1.score }
            
        } withCancel: { error in
            print("Erreur Firebase: Échec de l'observation du classement: \(error.localizedDescription)")
        }
    }
    
    func stopObservingLeaderboard() {
        if let handle = leaderboardHandle {
            databaseRef.removeObserver(withHandle: handle)
            leaderboardHandle = nil
        }
    }
    
    // --- NOUVEAU : FONCTIONS PVP (Déplacées de l'extension) ---

    /// Envoie une attaque à un joueur cible via Firebase.
    func sendAttack(targetUserID: String, item: ShopItem, senderUsername: String) {
        
        guard let attackID = item.effectID else {
            print("Erreur: L'objet Perturbateur n'a pas d'effectID.")
            return
        }

        let remoteAttack = RemoteAttack(
            attackID: attackID,
            senderUsername: senderUsername,
            timestamp: Date(),
            durationMinutes: item.durationMinutes
        )

        // Conversion en dictionnaire pour Firebase (via extension Encodable)
        guard let attackData = remoteAttack.toDictionary() else {
            print("Erreur: Impossible de sérialiser l'attaque.")
            return
        }

        // Chemin de la base de données cible: users/{targetUserID}/attacks/{uniqueKey}
        let attackPath = "users/\(targetUserID)/attacks"
        
        // Utilisation de la référence de base 'db'
        db.child(attackPath).childByAutoId().setValue(attackData) { error, _ in
            if let error = error {
                print("Erreur Firebase lors de l'envoi de l'attaque: \(error.localizedDescription)")
            } else {
                print("Attaque \(attackID) envoyée avec succès à \(targetUserID)")
            }
        }
    }

    /// Lance l'observateur pour écouter les attaques reçues par l'utilisateur local.
    func startObservingIncomingAttacks(data: GameData) {
        stopObservingIncomingAttacks() // S'assurer qu'un seul observateur est actif
        
        // Le chemin d'écoute est le nœud 'attacks' de l'utilisateur local
        let attackPath = "users/\(self.userID)/attacks"
        
        // Observez les enfants ajoutés pour détecter les nouvelles attaques
        attacksHandle = db.child(attackPath).observe(.childAdded) { snapshot in
            
            // 1. Désérialiser les données
            guard let value = snapshot.value as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: value),
                  let incomingAttack = try? JSONDecoder().decode(RemoteAttack.self, from: jsonData)
            else {
                print("Erreur: Impossible de décoder l'attaque entrante.")
                return
            }
            
            // 2. Appliquer l'effet via GameData (la logique de défense est dans GameData)
            let success = data.applyAttack(effectID: incomingAttack.attackID,
                                           duration: incomingAttack.durationMinutes)
            
            if success {
                print("Attaque reçue : \(incomingAttack.attackID) de \(incomingAttack.senderUsername). Effet appliqué.")
                // TO DO: Déclencher une notification visuelle ou sonore.
            } else {
                print("Attaque bloquée par la défense locale.")
            }
            
            // 3. IMPORTANT : Supprimer l'attaque du serveur après l'avoir traitée localement
            // (Ceci empêche que l'attaque soit appliquée à chaque redémarrage de l'app)
            self.db.child(attackPath).child(snapshot.key).removeValue()
        }
    }
    
    func stopObservingIncomingAttacks() {
        if let handle = attacksHandle {
            // Remarque: il n'y a pas d'URL spécifique ici car nous utilisons la référence de base 'db'
            db.child("users/\(self.userID)/attacks").removeObserver(withHandle: handle)
            attacksHandle = nil
        }
    }
}
