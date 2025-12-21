import SwiftUI
import Combine

class GameTimerManager: ObservableObject {
    // On a besoin de références vers les autres managers pour les mettre à jour
    private var data: GameData
    private var poopManager: PoopEntityManager
    
    private var timer: Timer?
    private var petAccumulator: Double = 0.0
    private let tickInterval: Double = 0.05
    
    init(data: GameData, poopManager: PoopEntityManager) {
        self.data = data
        self.poopManager = poopManager
    }
    
    func startAutoFartTimer() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.updateGains()
        }
    }
    
    private func updateGains() {
        let pps = data.petsPerSecond
        if pps <= 0 { return }
        
        // Calcul mathématique
        petAccumulator += pps * tickInterval
        
        if petAccumulator >= 1.0 {
            let newPoints = Int(petAccumulator)
            
            // Mise à jour sur le fil principal pour SwiftUI
            DispatchQueue.main.async {
                self.data.totalFartCount += newPoints
                self.data.lifetimeFarts += newPoints
                self.petAccumulator -= Double(newPoints)
                
                // Déclenchement de la pluie
                self.triggerPoopRain(producedAmount: newPoints)
                
                // Vérification des succès/notifs
                self.data.checkNotifications()
            }
        }
    }
    
    private func triggerPoopRain(producedAmount: Int) {
        let num = min(max(producedAmount / 50, 1), 15)
        poopManager.generatePoopRain(count: num)
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
