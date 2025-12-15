import SwiftUI

// NOTE: Assurez-vous que le fichier StyleConstants.swift est bien créé et contient AppStyle et CustomTitleBar.

struct LeaderboardView: View {
    @ObservedObject var gameManager: GameManager
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Fond sombre unifié
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Barre de Titre (Style unifié)
                CustomTitleBar(title: "Classement 🏆", onDismiss: { dismiss() })
                
                // Conteneur Scrollable pour le classement
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
                            // BOUCLE DE CLASSEMENT RÉINTÉGRÉE ICI
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
                                    
                                    // Score
                                    Text("\(entry.score)")
                                        // Utilisation du monospaced pour un alignement propre des chiffres
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.bold)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                // Highlight de la ligne du joueur actuel
                                .background(entry.id == gameManager.userID ? Color.orange.opacity(0.2) : AppStyle.listRowBackground)
                                .cornerRadius(5)
                            }
                        }
                        
                    }
                    .padding(AppStyle.defaultPadding)
                }
                .onAppear {
                    // Chargement des données à l'ouverture
                    gameManager.fetchLeaderboard()
                }
                .refreshable {
                    // Permet de rafraîchir en tirant vers le bas
                    gameManager.fetchLeaderboard()
                }
            }
        }
    }
}
