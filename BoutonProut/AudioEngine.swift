import AVFoundation
import Foundation
import SwiftUI
import Combine

// Configuration
let numberOfFarts = 7
let soundExtension = "mp3"

class AudioEngine: ObservableObject {
    
    // On garde tous les lecteurs en mémoire pour qu'ils soient prêts instantanément
    private var players: [AVAudioPlayer] = []
    
    init() {
        // Au démarrage de l'appli, on prépare tout de suite les sons
        prepareAudioSession()
        preloadSounds()
    }
    
    // 1. Configurer le matériel audio du téléphone (Haut-parleur)
    private func prepareAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Erreur activation session audio: \(error.localizedDescription)")
        }
    }
    
    // 2. Charger les 7 fichiers en mémoire MAINTENANT (pas au clic)
    private func preloadSounds() {
        for i in 1...numberOfFarts {
            let soundName = "prout\(i)"
            
            if let url = Bundle.main.url(forResource: soundName, withExtension: soundExtension) {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay() // C'est la commande magique qui supprime le lag
                    players.append(player)
                } catch {
                    print("Erreur chargement \(soundName): \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 3. Jouer le son (C'est maintenant instantané)
    func triggerFart(isAuto: Bool) {
        // Sécurité : si aucun son n'est chargé
        guard !players.isEmpty else { return }
        
        // Choisir un lecteur au hasard parmi ceux chargés
        let randomIndex = Int.random(in: 0..<players.count)
        let player = players[randomIndex]
        
        // Réglage du volume
        // isAuto = true -> Volume bas (0.1) | isAuto = false -> Volume fort (1.0)
        player.volume = isAuto ? 0.1 : 1.0
        
        // Si le son était déjà en train de jouer, on le remet au début (pour pouvoir spammer le bouton)
        if player.isPlaying {
            player.stop()
            player.currentTime = 0
        }
        
        player.play()
        
        // Petit retour haptique (vibration) pour renforcer la sensation de réactivité
        if !isAuto {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
}
