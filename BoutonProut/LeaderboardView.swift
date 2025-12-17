import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var gameManager: GameManager
    @ObservedObject var data: GameData
    @Environment(\.dismiss) var dismiss
    
    // On récupère TOUS les perturbateurs possédés pour le menu
    var ownedAttacks: [ShopItem] {
        return data.allItems.filter { item in
            item.category == .perturbateur && data.itemLevels[item.name, default: 0] > 0
        }
    }
    
    var body: some View {
        ZStack {
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                CustomTitleBar(title: "Classement 🏆", onDismiss: { dismiss() })
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        // En-tête
                        HStack {
                            Text("Rang").frame(width: 40, alignment: .leading)
                            Text("Nom du Prouteur")
                            Spacer()
                            Text("Score")
                        }
                        .font(AppStyle.bodyFont).fontWeight(.bold)
                        .foregroundColor(AppStyle.accentColor).padding(.horizontal, 10)
                        
                        if gameManager.leaderboard.isEmpty {
                            Text("Chargement...").foregroundColor(.gray).padding().frame(maxWidth: .infinity)
                        } else {
                            ForEach(gameManager.leaderboard.indices, id: \.self) { index in
                                let entry = gameManager.leaderboard[index]
                                
                                HStack {
                                    Text("#\(index + 1)").font(.headline).frame(width: 30, alignment: .leading)
                                    
                                    Text(entry.username)
                                        .fontWeight(entry.id == gameManager.userID ? .heavy : .regular)
                                        .foregroundColor(entry.id == gameManager.userID ? AppStyle.accentColor : .white)
                                    
                                    Spacer()
                                    
                                    // UN SEUL BOUTON ICI : Le Menu d'attaque
                                    if !ownedAttacks.isEmpty && entry.id != gameManager.userID {
                                        Menu {
                                            ForEach(ownedAttacks, id: \.id) { attack in
                                                Button {
                                                    gameManager.sendAttack(
                                                        targetUserID: entry.id,
                                                        item: attack,
                                                        senderUsername: gameManager.username
                                                    )
                                                    data.itemLevels[attack.name] = 0
                                                } label: {
                                                    Label("\(attack.name) (\(attack.emoji))", systemImage: "bolt.fill")
                                                }
                                            }
                                        } label: {
                                            Text("Attaquer ⚔️")
                                                .font(.caption).fontWeight(.bold)
                                                .padding(6).background(Color.red).foregroundColor(.white).cornerRadius(8)
                                        }
                                    }
                                    
                                    Text("\(entry.score)").font(.system(.body, design: .monospaced)).fontWeight(.bold)
                                }
                                .padding(.vertical, 8).padding(.horizontal, 10)
                                .background(entry.id == gameManager.userID ? AppStyle.accentColor.opacity(0.3) : AppStyle.listRowBackground)
                                .cornerRadius(5)
                            }
                        }
                    }
                    .padding(AppStyle.defaultPadding)
                }
                .onAppear { gameManager.startObservingLeaderboard() }
                .onDisappear { gameManager.stopObservingLeaderboard() }
            }
        }
    }
}
