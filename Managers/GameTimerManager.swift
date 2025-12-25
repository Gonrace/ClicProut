import SwiftUI
import Combine
import FirebaseAuth

class GameTimerManager: ObservableObject {
    
    // --- PROPRIÉTÉS ---
    private var data: GameData
    private var poopManager: PoopEntityManager
    
    // Références optionnelles vers les autres managers (injectées après l'init)
    var squadManager: SquadManager?
    var authManager: AuthManager?
    
    private var timer: Timer?
    private var petAccumulator: Double = 0.0
    private let tickInterval: Double = 0.05
    
    // --- INITIALISATION ---
    init(data: GameData, poopManager: PoopEntityManager) {
        self.data = data
        self.poopManager = poopManager
    }
    
    // --- LOGIQUE DU TIMER ---
    
    func startAutoFartTimer() {
        // On attend 2 secondes que Firebase synchronise l'escouade avant de calculer
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.checkOfflineGains()
        }
        
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.updateGains()
        }
    }
    
    private func updateGains() {
        var pps = data.petsPerSecond
        if pps <= 0 { return }
        
        // --- MULTIPLICATEUR TEMPS RÉEL ---
        // Si tout le monde est connecté, on double la production en direct
        if squadManager?.isFullSquadOnline() == true {
            pps *= 2
        }
        
        // Calcul mathématique de la production sur le tick actuel
        petAccumulator += pps * tickInterval
        
        if petAccumulator >= 1.0 {
            let newPoints = Int(petAccumulator)
            
            // Mise à jour sur le fil principal pour l'UI
            DispatchQueue.main.async {
                self.data.totalFartCount += newPoints
                self.data.lifetimeFarts += newPoints
                self.petAccumulator -= Double(newPoints)
                
                // Déclenchement visuel
                self.triggerPoopRain(producedAmount: newPoints)
                
                // Vérification des succès
                self.data.checkNotifications()
            }
        }
    }
    
    // --- LOGIQUE HORS-LIGNE (OFFLINE) ---
    
    private func checkOfflineGains() {
        // 1. Récupérer la date de la dernière sortie sauvegardée
        guard let lastExit = UserDefaults.standard.object(forKey: "LastExitDate") as? Date else {
            return
        }
        
        let secondsAway = Date().timeIntervalSince(lastExit)
        
        // --- CORRECTION ICI ---
        // On envoie l'objet Squad complet au lieu d'un simple Bool (isActive)
        // Cela permet à GameData de comparer les dates (pro-rata)
        let currentSquad = squadManager?.currentSquad
        
        // 3. Appliquer les gains calculés dans GameData (Nouvelle signature)
        data.applyOfflineGains(seconds: secondsAway, squad: currentSquad)
        
        // 4. Nettoyer la sauvegarde
        UserDefaults.standard.removeObject(forKey: "LastExitDate")
    }
    
    func stopTimer() {
        // Sauvegarder l'instant présent pour le prochain calcul hors-ligne
        UserDefaults.standard.set(Date(), forKey: "LastExitDate")
        
        timer?.invalidate()
        timer = nil
    }
    
    // --- HELPERS ---
    
    private func triggerPoopRain(producedAmount: Int) {
        let num = min(max(producedAmount / 50, 1), 15)
        poopManager.generatePoopRain(count: num)
    }
}
