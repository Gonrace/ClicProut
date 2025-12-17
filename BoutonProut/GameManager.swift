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
    private let db = Database.database(url: FIREBASE_DATABASE_URL).reference()
    private let leaderboardRef: DatabaseReference

    @Published var username: String = "Inconnu"
    @Published var leaderboard: [LeaderboardEntry] = []
    
    // Handles pour gérer les écouteurs en temps réel
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
        // On pointe sur le noeud "leaderboard"
        self.leaderboardRef = db.child("leaderboard")
        
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
        
        leaderboardRef.child(userID).setValue(entry) { error, _ in
            if let error = error {
                print("❌ Erreur Firebase Score: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - LOGIQUE DU CLASSEMENT
    
    /// Écoute les changements du classement en temps réel
    func startObservingLeaderboard() {
        stopObservingLeaderboard()
        
        // On récupère les 100 meilleurs scores
        let query = leaderboardRef.queryOrdered(byChild: "score").queryLimited(toLast: 100)
        
        leaderboardHandle = query.observe(.value) { snapshot in
            var fetchedEntries: [LeaderboardEntry] = []
            
            guard let value = snapshot.value as? [String: [String: Any]] else {
                DispatchQueue.main.async { self.leaderboard = [] }
                return
            }
            
            for (id, data) in value {
                if let username = data["username"] as? String,
                   let score = data["score"] as? Int {
                    fetchedEntries.append(LeaderboardEntry(id: id, username: username, score: score))
                }
            }
            
            // Mise à jour de la liste triée sur le fil principal
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

        // Chemin : users/ID_CIBLE/attacks
        let attackPath = "users/\(targetUserID)/attacks"
        
        db.child(attackPath).childByAutoId().setValue(attackData) { error, _ in
            if let error = error {
                print("❌ Erreur envoi attaque: \(error.localizedDescription)")
            } else {
                print("🚀 Attaque \(item.name) envoyée avec succès !")
            }
        }
    }

    /// Écoute les attaques entrantes (Seulement si l'Acte 2 est débloqué)
    func startObservingIncomingAttacks(data: GameData) {
        stopObservingIncomingAttacks()
        
        // SÉCURITÉ : Si on n'a pas débloqué la méchanceté (Acte 2), on n'écoute rien.
        // Cela évite de recevoir des malus alors qu'on est encore "bébé".
        guard data.isActeUnlocked(2) else {
            print("🛡️ Mode Pacifique : Écouteur d'attaques désactivé.")
            return
        }
        
        let attackPath = "users/\(self.userID)/attacks"
        print("📡 Écoute des attaques sur : \(attackPath)")
        
        // On écoute chaque nouvel ajout dans le dossier attacks
        attacksHandle = db.child(attackPath).observe(.childAdded) { [weak self] snapshot in
            guard let self = self else { return }
            
            // 1. Décodage sécurisé de l'objet Firebase
            guard let value = snapshot.value as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: value),
                  let incomingAttack = try? JSONDecoder().decode(RemoteAttack.self, from: jsonData)
            else { return }
            
            // 2. Recherche du nom de l'arme pour l'UI
            let weaponName = data.allItems.first(where: { $0.effectID == incomingAttack.attackID })?.name ?? "Attaque mystère"
            
            // 3. Application de l'effet dans le moteur de jeu
            DispatchQueue.main.async {
                data.applyAttack(
                    effectID: incomingAttack.attackID,
                    duration: incomingAttack.durationMinutes,
                    attackerName: incomingAttack.senderUsername,
                    weaponName: weaponName
                )
            }

            print("🔥 ALERTE : \(incomingAttack.senderUsername) a utilisé \(weaponName) sur vous !")

            // 4. Nettoyage immédiat : On supprime l'attaque de Firebase pour ne pas la recevoir deux fois
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
