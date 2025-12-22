import Foundation
import FirebaseDatabase
import Combine

class SocialManager: ObservableObject {
    private var db: DatabaseReference? // Devient optionnel
    
    // On injecte la référence depuis le CloudManager
    func setup(with ref: DatabaseReference) {
        self.db = ref
    }
    
    private var attacksHandle: DatabaseHandle?
    private var giftsHandle: DatabaseHandle?
    
    private var userID: String {
        UserDefaults.standard.string(forKey: "userID") ?? "unknown"
    }

    // MARK: - ENVOI (Émetteur)
    
    func sendAttack(targetID: String, item: ShopItem, myName: String) {
        print("🚀 Tentative d'attaque sur : \(targetID)") // Debug
        guard let effectID = item.effectID else { return }
        let duration = item.durationSec / 60
        
        let attack = RemoteAttack(
            attackID: effectID,
            senderUsername: myName,
            timestamp: Date(),
            durationMinutes: duration > 0 ? duration : 1
        )
        
        if let data = attack.toDictionary() {
            // AJOUT D'UN CALLBACK POUR VOIR L'ERREUR DANS XCODE
            db?.child("users").child(targetID).child("attacks").childByAutoId()
                .setValue(data) { error, _ in
                    if let error = error {
                        print("❌ Erreur Firebase Attaque: \(error.localizedDescription)")
                    } else {
                        print("✅ Attaque notée dans Firebase !")
                    }
                }
        }
    }
    
    func sendGift(targetID: String, item: ShopItem, myName: String) {
        print("🎁 Tentative d'envoi cadeau sur : \(targetID)") // Debug
        guard let effectID = item.effectID else { return }
        
        let gift = RemoteGift(
            giftID: effectID,
            senderName: myName,
            timestamp: Date()
        )
        
        if let data = gift.toDictionary() {
            // AJOUT D'UN CALLBACK POUR VOIR L'ERREUR DANS XCODE
            db?.child("users").child(targetID).child("gifts").childByAutoId()
                .setValue(data) { error, _ in
                    if let error = error {
                        print("❌ Erreur Firebase Cadeau: \(error.localizedDescription)")
                    } else {
                        print("✅ Cadeau noté dans Firebase !")
                    }
                }
        }
    }

    // MARK: - RÉCEPTION (Récepteur)
    
    // MARK: - RÉCEPTION (Récepteur)
        
        func startObservingInteractions(gameData: GameData) {
            stopObservingAll()
            print("📡 SocialManager: Début de l'écoute pour \(userID)")
            
            // 1. Écoute des Attaques
            attacksHandle = db?.child("users").child(userID).child("attacks").observe(.childAdded) { (snapshot: DataSnapshot, _) in
                guard let value = snapshot.value as? [String: Any] else { return }
                
                let id = value["attackID"] as? String ?? ""
                let sender = value["senderUsername"] as? String ?? "Inconnu"
                let duration = value["durationMinutes"] as? Int ?? 1
                
                // Récupération sécurisée via le cloudManager
                let items = gameData.cloudManager?.allItems ?? []
                let weapon = items.first(where: { $0.effectID == id })?.name ?? "Attaque"
                
                DispatchQueue.main.async {
                    gameData.applyAttack(effectID: id, duration: duration, attackerName: sender, weaponName: weapon)
                }
                snapshot.ref.removeValue()
            }
            
            // 2. Écoute des Cadeaux
            giftsHandle = db?.child("users").child(userID).child("gifts").observe(.childAdded) { (snapshot: DataSnapshot, _) in
                guard let value = snapshot.value as? [String: Any] else { return }
                
                let id = value["giftID"] as? String ?? ""
                let sender = value["senderName"] as? String ?? "Inconnu"
                
                DispatchQueue.main.async {
                    gameData.applyGift(giftID: id, from: sender)
                }
                snapshot.ref.removeValue()
            }
        }
    
    func stopObservingAll() {
        if let handle = attacksHandle {
            db?.child("users").child(userID).child("attacks").removeObserver(withHandle: handle)
            attacksHandle = nil
        }
        if let handle = giftsHandle {
            db?.child("users").child(userID).child("gifts").removeObserver(withHandle: handle)
            giftsHandle = nil
        }
    }
}
