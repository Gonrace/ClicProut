import SwiftUI

struct MainButtonView: View {
    @ObservedObject var data: GameData
    let action: () -> Void
    
    // On déplace les états d'animation ici pour qu'ils ne ralentissent pas ContentView
    @State private var pressScale: CGFloat = 1.0
    
    var body: some View {
        Text(currentEmoji)
            .font(.system(size: 110))
            .shadow(color: shadowColor, radius: 30)
            // L'effet de grossissement permanent selon le score
            .scaleEffect(1.0 + min(CGFloat(data.totalFartCount) / 100000.0, 0.4))
            // L'effet de rebond au clic
            .scaleEffect(pressScale)
            .onTapGesture {
                self.triggerFeedback()
                action()
            }
            // On garde le geste simultané pour l'animation de pression
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in animate(isPressed: true) }
                    .onEnded { _ in animate(isPressed: false) }
            )
    }
    
    // MARK: - LOGIQUE DYNAMIQUE (C'est ici que tu t'amuseras plus tard !)
    
    private var currentEmoji: String {
        return "💩"
    }
    
    private var shadowColor: Color {
        // Le bouton brille en rouge si on est attaqué
        data.isUnderAttack ? .red : .yellow.opacity(0.8)
    }
    
    private func animate(isPressed: Bool) {
        withAnimation(.spring(response: 0.1, dampingFraction: 0.4)) {
            self.pressScale = isPressed ? 0.8 : 1.0
        }
    }
    
    private func triggerFeedback() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
