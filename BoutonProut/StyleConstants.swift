import SwiftUI

// --- 1. CONSTANTES DE STYLE GLOBALES ---
struct AppStyle {
    // COULEURS
    static let primaryBackground = Color(red: 0.1, green: 0.15, blue: 0.2)
    static let secondaryBackground = Color(red: 0.1, green: 0.1, blue: 0.15)
    static let listRowBackground = Color.white.opacity(0.1)
    static let accentColor = Color.yellow
    static let warningColor = Color.red
    static let positiveColor = Color.green
    static let secondaryTextColor = Color.gray
    static let secondaryButtonColor = Color.gray.opacity(0.3)
    
    // TYPOGRAPHIE
    static let titleFont: Font = .largeTitle
    static let subTitleFont: Font = .title3
    static let bodyFont: Font = .body
    
    // PADDING
    static let defaultPadding: CGFloat = 20
}

// --- 2. COMPOSANT DE BARRE DE TITRE UNIFIÉE ---
// Cette structure est rendue publique pour être utilisée par LeaderboardView, StatsView, et ShopView.
struct CustomTitleBar: View {
    let title: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppStyle.titleFont)
                .fontWeight(.heavy)
                .foregroundColor(.white)
            Spacer()
            Button("Fermer") {
                onDismiss()
            }
            .padding(8)
            .background(AppStyle.warningColor.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(.horizontal, AppStyle.defaultPadding)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
}
