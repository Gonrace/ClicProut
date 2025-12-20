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
        stopObservingIncomingAttacks()
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
    
    // MARK: - LOGIQUE PVP DYNAMIQUE
    
    func sendAttack(targetUserID: String, item: ShopItem, senderUsername: String) {
        guard let attackID = item.effectID else { return }
        
        let duration = item.durationSec / 60
        
        let remoteAttack = RemoteAttack(
            attackID: attackID,
            senderUsername: senderUsername,
            timestamp: Date(),
            durationMinutes: duration > 0 ? duration : 1 // Sécurité: minimum 1 min
        )
        
        guard let attackData = remoteAttack.toDictionary() else { return }
        let attackPath = "users/\(targetUserID)/attacks"
        
        db.child(attackPath).childByAutoId().setValue(attackData)
    }
    
    func startObservingIncomingAttacks(data: GameData) {
        stopObservingIncomingAttacks()
        
        // Sécurité Acte 2
        guard data.isActeUnlocked(2) else { return }
        
        let attackPath = "users/\(self.userID)/attacks"
        
        attacksHandle = db.child(attackPath).observe(.childAdded) { [weak self] snapshot, _ in
            guard let self = self else { return }
            
            // 1. Décodage
            guard let value = snapshot.value as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: value),
                  let incomingAttack = try? JSONDecoder().decode(RemoteAttack.self, from: jsonData)
            else { return }
            
            // 2. Identification dynamique via allItems (chargé par le CSV)
            // On cherche l'objet dans la liste globale pour avoir son nom et ses multiplicateurs
            let weapon = data.allItems.first(where: { $0.effectID == incomingAttack.attackID })
            let weaponName = weapon?.name ?? "Attaque mystère"
            
            // 3. Application immédiate
            DispatchQueue.main.async {
                data.applyAttack(
                    effectID: incomingAttack.attackID,
                    duration: incomingAttack.durationMinutes,
                    attackerName: incomingAttack.senderUsername,
                    weaponName: weaponName
                )
            }
            
            // 4. Nettoyage Firebase
            self.db.child(attackPath).child(snapshot.key).removeValue()
        }
    }
    
    func stopObservingIncomingAttacks() {
        if let handle = attacksHandle {
            db.child("users/\(self.userID)/attacks").removeObserver(withHandle: handle)
            attacksHandle = nil
        }
    }
    // MARK: - SYSTÈME DE CADEAUX
    func sendGift(targetUserID: String, giftItem: ShopItem, senderUsername: String) {
        // 1. On cible le dossier "gifts" de l'ami sur Firebase
        // Chemin : users / ID_AMI / gifts
        let recipientGiftRef = Database.database().reference()
            .child("users")
            .child(targetUserID)
            .child("gifts")
            .childByAutoId() // Génère un ID unique pour ce cadeau (pour ne pas écraser les autres)
        
        // 2. On prépare les données à envoyer
        let giftData: [String: Any] = [
            "giftID": giftItem.effectID ?? "gift_default", // L'ID qui correspond au Google Sheet
            "senderName": senderUsername,                  // Ton pseudo
            "timestamp": ServerValue.timestamp()           // L'heure de l'envoi
        ]
        
        // 3. On envoie sur le Cloud
        recipientGiftRef.setValue(giftData) { error, _ in
            if let error = error {
                print("❌ Erreur envoi cadeau : \(error.localizedDescription)")
            } else {
                print("✅ Cadeau '\(giftItem.name)' envoyé avec succès à \(targetUserID) !")
            }
        }
    }
}
