import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var gameManager: GameManager
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Barre de Titre (Style unifié)
                CustomTitleBar(title: "Classement 🏆", onDismiss: { dismiss() })
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        
                        // En-tête des colonnes
                        HStack {
                            Text("Rang")
                                .frame(width: 40, alignment: .leading)
                            Text("Nom du Prouteur")
                            Spacer()
                            Text("Score")
                        }
                        .font(AppStyle.bodyFont)
                        .fontWeight(.bold)
                        .foregroundColor(AppStyle.accentColor)
                        .padding(.horizontal, 10)
                        
                        // Lignes du classement
                        if gameManager.leaderboard.isEmpty {
                            Text("Chargement du classement ou aucune donnée disponible...")
                                .foregroundColor(AppStyle.secondaryTextColor)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(AppStyle.listRowBackground)
                                .cornerRadius(5)
                        } else {
                            ForEach(gameManager.leaderboard.indices, id: \.self) { index in
                                let entry = gameManager.leaderboard[index]
                                
                                HStack {
                                    // Classement
                                    Text("#\(index + 1)")
                                        .font(.headline)
                                        .frame(width: 30, alignment: .leading)
                                    
                                    // Nom de l'utilisateur
                                    Text(entry.username)
                                        .lineLimit(1)
                                        .fontWeight(entry.id == gameManager.userID ? .heavy : .regular)
                                        .foregroundColor(entry.id == gameManager.userID ? AppStyle.accentColor : .white)
                                    
                                    Spacer()
                                    
                                    // Score (qui est maintenant le lifetimeFarts)
                                    Text("\(entry.score)")
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.bold)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(entry.id == gameManager.userID ? Color.orange.opacity(0.2) : AppStyle.listRowBackground)
                                .cornerRadius(5)
                            }
                        }
                        
                    }
                    .padding(AppStyle.defaultPadding)
                }
                // Démarre l'observation en temps réel
                .onAppear {
                    gameManager.startObservingLeaderboard()
                }
                // Arrête l'observation quand la vue est fermée
                .onDisappear {
                    gameManager.stopObservingLeaderboard()
                }
                // Suppression de .refreshable car l'update est automatique
            }
        }
    }
}
