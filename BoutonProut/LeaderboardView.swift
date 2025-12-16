import SwiftUI

// NOTE: Assurez-vous que les classes GameManager et GameData sont définies.
// NOTE: Supposons que AppStyle, CustomTitleBar, et les structures de Leaderboard existent.

struct LeaderboardView: View {
    
    @ObservedObject var gameManager: GameManager
    @ObservedObject var data: GameData
    
    @Environment(\.dismiss) var dismiss
    
    /// Propriété calculée pour trouver le premier objet Perturbateur disponible
    var availableAttackItem: ShopItem? {
        return data.allItems.first { item in
            // Est-ce un perturbateur ET est-ce que le joueur en possède au moins un ?
            return item.category == .perturbateur && data.itemLevels[item.name, default: 0] > 0
        }
    }
    
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
                                    // NOTE: J'ai utilisé 'gameManager.userID' supposant que c'est l'ID du joueur local.
                                    // Si vous utilisez 'gameManager.currentUserID', corrigez cette ligne.
                                    Text(entry.username)
                                        .lineLimit(1)
                                        .fontWeight(entry.id == gameManager.userID ? .heavy : .regular)
                                        .foregroundColor(entry.id == gameManager.userID ? AppStyle.accentColor : .white)
                                    
                                    Spacer()
                                    
                                    // BOUTON ATTAQUER CONDITIONNEL
                                    // Correction : Utilisez 'entry.id' pour vérifier la cible, et 'gameManager.userID' pour l'expéditeur local.
                                    // Assurez-vous que l'utilisateur local ne s'attaque pas lui-même et qu'il possède un item d'attaque.
                                    if let attackItem = availableAttackItem, entry.id != gameManager.userID {
                                        
                                        Button("Attaquer ⚔️") {
                                            
                                            // 1. Envoyer l'attaque via le GameManager
                                            gameManager.sendAttack(
                                                targetUserID: entry.id,
                                                item: attackItem,
                                                senderUsername: gameManager.username
                                            )
                                            
                                            // 2. Consommation de l'objet localement (réduit le niveau à 0)
                                            data.itemLevels[attackItem.name] = 0
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.red)
                                    }
                                    
                                    // Score (qui est maintenant le lifetimeFarts)
                                    Text("\(entry.score)")
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.bold)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                // Mise en surbrillance de l'utilisateur local
                                .background(entry.id == gameManager.userID ? AppStyle.accentColor.opacity(0.3) : AppStyle.listRowBackground)
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
            }
        }
    }
}
