import SwiftUI

struct NotificationOverlay: View {
    @ObservedObject var data: GameData
    
    var body: some View {
        if data.showNotificationOverlay, let notif = data.pendingNotification {
            ZStack {
                // Fond sombre unifié avec l'opacité
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                
                VStack(spacing: 15) {
                    // Icône thématique
                    Text("📢")
                        .font(.system(size: 40))
                        .offset(y: -25)
                        .padding(.bottom, -25)
                    
                    VStack(spacing: 8) {
                        // Utilisation du sous-titre de l'AppStyle
                        Text(notif.title)
                            .font(AppStyle.subTitleFont)
                            .fontWeight(.black)
                            .foregroundColor(AppStyle.accentColor)
                            .multilineTextAlignment(.center)
                        
                        // Utilisation du corps de texte de l'AppStyle
                        Text(notif.message)
                            .font(AppStyle.bodyFont)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Bouton unifié
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            data.showNotificationOverlay = false
                        }
                    }) {
                        Text("GÉNIAL !")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppStyle.secondaryBackground) // Texte sombre sur fond clair
                            .padding(.vertical, 10)
                            .padding(.horizontal, 30)
                            .background(AppStyle.accentColor)
                            .cornerRadius(12)
                            .shadow(color: AppStyle.accentColor.opacity(0.3), radius: 5)
                    }
                    .padding(.top, 5)
                }
                .padding(AppStyle.defaultPadding)
                .frame(width: 280)
                .background(
                    // Utilisation du fond secondaire de l'AppStyle
                    AppStyle.secondaryBackground
                )
                .cornerRadius(30)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(AppStyle.accentColor.opacity(0.5), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.5), radius: 20)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
            .zIndex(999)
        }
    }
}
