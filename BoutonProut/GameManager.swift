import Foundation
import FirebaseDatabase
import Combine

// URL de la base de données Firebase (Région Europe-West1)
let FIREBASE_DATABASE_URL = "https://clicprout-default-rtdb.europe-west1.firebasedatabase.app"

// MARK: - STRUCTURES DE DONNÉES
struct LeaderboardEntry: Identifiable, Decodable {
    let id: String
    let username: String
    let score: Int
}

/// Gère toutes les interactions avec Firebase (Classement et PvP)
class GameManager: ObservableObject {
    
    // Références Firebase
    private let db = Database.database().reference() // Référence racine
    private let databaseRef: DatabaseReference       // Référence vers le noeud "leaderboard"

    @Published var username: String = "Inconnu"
    @Published var leaderboard: [LeaderboardEntry] = []
    
    // Handles pour gérer les écouteurs en temps réel (permet de les arrêter proprement)
    private var leaderboardHandle: DatabaseHandle?
    private var attacksHandle: DatabaseHandle?
    
    // MARK: - GESTION DE L'IDENTIFIANT UNIQUE
    /// Identifiant unique de l'appareil sauvegardé dans UserDefaults
    var userID: String {
        if let id = UserDefaults.standard.string(forKey: "userID") {
            return id
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: "userID")
        return newID
    }
    
    // MARK: - INITIALISATION
    init() {
        // Initialisation de la connexion avec l'URL spécifique
        Database.database().reference(fromURL: FIREBASE_DATABASE_URL).observeSingleEvent(of: .value) { _ in }
        
        // On pointe spécifiquement sur le noeud "leaderboard"
        self.databaseRef = Database.database(url: FIREBASE_DATABASE_URL).reference().child("leaderboard")
        
        // Chargement ou création du pseudo
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
    
    // MARK: - GESTION DU PROFIL
    
    /// Modifie le pseudo et met à jour le classement Firebase
    func saveNewUsername(_ newName: String, lifetimeScore: Int) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        UserDefaults.standard.set(trimmedName, forKey: "username")
        self.username = trimmedName
        
        self.saveLifetimeScore(lifetimeScore: lifetimeScore)
    }

    /// Sauvegarde le score à vie de l'utilisateur sur Firebase
    func saveLifetimeScore(lifetimeScore: Int) {
        let entry: [String: Any] = [
            "username": self.username,
            "score": lifetimeScore
        ]
        
        databaseRef.child(userID).setValue(entry) { error, _ in
            if let error = error {
                print("Erreur Firebase Score: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - LOGIQUE DU CLASSEMENT
    
    /// Écoute les changements du classement en temps réel
    func startObservingLeaderboard() {
        stopObservingLeaderboard()
        
        // On récupère les 100 meilleurs scores
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
            
            // Tri du plus grand au plus petit
            self.leaderboard = fetchedEntries.sorted { $0.score > $1.score }
        }
    }
    
    func stopObservingLeaderboard() {
        if let handle = leaderboardHandle {
            databaseRef.removeObserver(withHandle: handle)
            leaderboardHandle = nil
        }
    }
    
    // MARK: - LOGIQUE PVP (ATTAQUES)

    /// Envoie une attaque à un autre joueur
    func sendAttack(targetUserID: String, item: ShopItem, senderUsername: String) {
        guard let attackID = item.effectID else { return }

        let remoteAttack = RemoteAttack(
            attackID: attackID,
            senderUsername: senderUsername,
            timestamp: Date(),
            durationMinutes: item.durationMinutes
        )

        // Conversion en dictionnaire pour Firebase
        guard let attackData = remoteAttack.toDictionary() else { return }

        // On écrit dans le dossier 'attacks' de la victime
        let attackPath = "users/\(targetUserID)/attacks"
        
        db.child(attackPath).childByAutoId().setValue(attackData) { error, _ in
            if let error = error {
                print("Erreur envoi attaque: \(error.localizedDescription)")
            } else {
                print("Attaque \(item.name) envoyée à \(targetUserID)")
            }
        }
    }

    /// Écoute les attaques qui arrivent sur notre propre compte
    func startObservingIncomingAttacks(data: GameData) {
        stopObservingIncomingAttacks()
        
        let attackPath = "users/\(self.userID)/attacks"
        
        // .childAdded permet de détecter chaque nouvelle attaque séparément
        attacksHandle = db.child(attackPath).observe(.childAdded) { snapshot in
            
            // 1. Décodage de l'attaque reçue
            guard let value = snapshot.value as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: value),
                  let incomingAttack = try? JSONDecoder().decode(RemoteAttack.self, from: jsonData)
            else { return }
            
            // On cherche le nom de l'arme dans la boutique pour l'afficher dans l'alerte
            let weaponName = standardShopItems.first(where: { $0.effectID == incomingAttack.attackID })?.name ?? "Attaque mystère"
            
            // 2. Application de l'effet dans GameData
            // On passe maintenant le pseudo de l'attaquant et le nom de l'arme
            let success = data.applyAttack(
                effectID: incomingAttack.attackID,
                duration: incomingAttack.durationMinutes,
                attackerName: incomingAttack.senderUsername,
                weaponName: weaponName
            )
            
            if success {
                print("🔥 \(incomingAttack.senderUsername) vous a attaqué avec \(weaponName) !")
            }
            
            // 3. Nettoyage : On supprime l'attaque de Firebase une fois reçue
            // pour ne pas qu'elle se redéclenche à chaque ouverture de l'app.
            self.db.child(attackPath).child(snapshot.key).removeValue()
        }
    }
    
    func stopObservingIncomingAttacks() {
        if let handle = attacksHandle {
            db.child("users/\(self.userID)/attacks").removeObserver(withHandle: handle)
            attacksHandle = nil
        }
    }
}
