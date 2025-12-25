import Foundation
import FirebaseDatabase
import FirebaseAuth
import Combine

class SquadManager: ObservableObject {
    @Published var currentSquad: Squad?
    
    private let ref = Database.database().reference()
    private var squadListener: DatabaseHandle?
    private var activityTimer: Timer?
    
    // --- 1. GESTION DE L'ESCOUADE (Créer/Rejoindre/Quitter) ---
    
    func createSquad(name: String, user: User, username: String) {
        let squadID = ref.child("squads").childByAutoId().key ?? UUID().uuidString
        let now = Date().timeIntervalSince1970
        
        let newSquad = Squad(
            id: squadID,
            name: name,
            leaderID: user.uid,
            members: [user.uid: username],
            lastSeen: [user.uid: now],
            lastActivity: now
        )
        
        // Sauvegarde dans Firebase : Dossier Squads + Dossier User
        try? ref.child("squads").child(squadID).setValue(from: newSquad)
        ref.child("users").child(user.uid).child("squadID").setValue(squadID)
        
        self.observeSquad(id: squadID)
    }

    func joinSquad(squadID: String, user: User, username: String) {
        let trimmedID = squadID.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Ajout dans la liste des membres de l'escouade
        ref.child("squads").child(trimmedID).child("members").child(user.uid).setValue(username)
        // 2. Lien dans le profil utilisateur
        ref.child("users").child(user.uid).child("squadID").setValue(trimmedID)
        
        self.observeSquad(id: trimmedID)
    }
    
    func leaveSquad(user: User) {
        guard let squad = currentSquad else { return }
        
        // 1. Retrait des données dans l'escouade
        ref.child("squads").child(squad.id).child("members").child(user.uid).removeValue()
        ref.child("squads").child(squad.id).child("lastSeen").child(user.uid).removeValue()
        
        // 2. Retrait du lien chez l'utilisateur
        ref.child("users").child(user.uid).child("squadID").removeValue()
        
        // 3. Arrêt de l'écoute et nettoyage local
        if let listener = squadListener {
            ref.child("squads").child(squad.id).removeObserver(withHandle: listener)
        }
        
        DispatchQueue.main.async {
            self.currentSquad = nil
        }
    }

    // --- 2. SYNCHRONISATION TEMPS RÉEL ---

    func observeUserSquad(user: User) {
        ref.child("users").child(user.uid).child("squadID").observeSingleEvent(of: .value) { snapshot in
            if let squadID = snapshot.value as? String {
                self.observeSquad(id: squadID)
            }
        }
    }

    func observeSquad(id: String) {
        if let listener = squadListener {
            ref.child("squads").removeObserver(withHandle: listener)
        }
        
        squadListener = ref.child("squads").child(id).observe(.value) { snapshot in
            if let squad = try? snapshot.data(as: Squad.self) {
                DispatchQueue.main.async {
                    self.currentSquad = squad
                }
            }
        }
    }
    
    // --- 3. LOGIQUE DE PRÉSENCE (Le Bonus) ---

    func updateMyActivity(userID: String) {
        guard let squadID = currentSquad?.id else {
            print("❌ Impossible d'update : Aucun squadID trouvé")
            return
        }
        let now = Date().timeIntervalSince1970
        
        // 1. Met à jour le timestamp pour le point vert
        ref.child("squads").child(squadID).child("lastSeen").child(userID).setValue(now)
        
        // 2. CRÉE LE DOSSIER activeSessions (C'est ça qui manque !)
        // On met 'true' pour dire que cet ID est en ligne
        ref.child("squads").child(squadID).child("activeSessions").child(userID).setValue(true)
        
        // 3. Met à jour l'activité globale pour les gains offline pro-rata
        ref.child("squads").child(squadID).child("lastActivity").setValue(now)
    }

    // Vérifie si AU MOINS un autre membre est en ligne (pour le gain offline)
    func isSquadActive(myID: String) -> Bool {
        let activityMap = currentSquad?.lastSeen ?? [:]
        let now = Date().timeIntervalSince1970
        let threshold: TimeInterval = 300 // 5 minutes
        
        return activityMap.contains { (userID, timestamp) in
            userID != myID && (now - timestamp) < threshold
        }
    }
    
    func setOffline(userID: String) {
        guard let squadID = currentSquad?.id else { return }
        // On supprime l'entrée dans activeSessions quand le joueur quitte
        ref.child("squads").child(squadID).child("activeSessions").child(userID).removeValue()
    }

    // Vérifie si UN membre précis est en ligne (pour le point vert/rouge de l'UI)
    func isUserOnline(userID: String) -> Bool {
        guard let squad = currentSquad, let lastSeenTime = squad.lastSeen[userID] else {
            return false
        }
        let now = Date().timeIntervalSince1970
        return (now - lastSeenTime) < 300 // 5 minutes
    }
    // Augmenter la fréquence de détection
    func startHeartbeat(userID: String) {
        activityTimer?.invalidate()
            
        // On marque l'utilisateur comme actif immédiatement
        ref.child("squads").child(currentSquad?.id ?? "").child("activeSessions").child(userID).setValue(true)
            
        // Heartbeat toutes les 10 secondes
        activityTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            self.updateMyActivity(userID: userID)
        }
    }

    func stopHeartbeat(userID: String) {
        activityTimer?.invalidate()
        if let squadID = currentSquad?.id {
            ref.child("squads").child(squadID).child("activeSessions").child(userID).removeValue()
        }
    }

    // Vérifier si TOUT LE MONDE est là (pour le x2)
    func isFullSquadOnline() -> Bool {
        guard let squad = currentSquad else { return false }
        
        let totalMembers = squad.members.count
        let onlineMembers = squad.activeSessions?.count ?? 0
        
        // Debug pour voir dans Xcode pourquoi ça ne s'affiche pas :
        print("Debug x2 : \(onlineMembers) en ligne sur \(totalMembers)")
        
        return onlineMembers >= totalMembers && totalMembers > 0
    }
}

