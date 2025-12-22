import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var gameManager: GameManager
    @ObservedObject var data: GameData
    @ObservedObject var socialManager: SocialManager
    @Environment(\.dismiss) var dismiss
    
    // 1. Filtre pour les attaques via cloudManager
    var ownedAttacks: [ShopItem] {
        // On récupère la liste des items depuis le cloudManager
        let allItems = data.cloudManager?.allItems ?? []
        return allItems.filter { item in
            item.category == .perturbateur && data.itemLevels[item.name, default: 0] > 0
        }
    }
    
    // 2. Filtre pour les cadeaux via cloudManager
    var ownedGifts: [ShopItem] {
        let allItems = data.cloudManager?.allItems ?? []
        return allItems.filter { item in
            item.category == .kado && data.itemLevels[item.name, default: 0] > 0
        }
    }
    
    var body: some View {
        ZStack {
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                CustomTitleBar(title: "Classement 🏆", onDismiss: { dismiss() })
                
                ScrollView {
                    VStack(spacing: 8) {
                        // --- EN-TÊTE FIXE ---
                        HStack {
                            Text("Rang").frame(width: 50, alignment: .leading)
                            Text("Prouteur").frame(maxWidth: .infinity, alignment: .leading)
                            Text("Score").frame(width: 80, alignment: .trailing)
                        }
                        .font(.caption).fontWeight(.black)
                        .foregroundColor(AppStyle.accentColor.opacity(0.8))
                        .padding(.horizontal, 15)
                        .padding(.bottom, 5)
                        
                        if gameManager.leaderboard.isEmpty {
                            VStack(spacing: 15) {
                                ProgressView()
                                Text("Récupération des champions...").font(.caption).foregroundColor(.gray)
                            }
                            .padding(.top, 50)
                        } else {
                            ForEach(gameManager.leaderboard.indices, id: \.self) { index in
                                let entry = gameManager.leaderboard[index]
                                let isMe = entry.id == gameManager.userID
                                
                                HStack(spacing: 10) {
                                    // 1. RANG
                                    Text("#\(index + 1)")
                                        .font(.system(.subheadline, design: .monospaced))
                                        .fontWeight(.bold)
                                        .frame(width: 40, alignment: .leading)
                                        .foregroundColor(isMe ? .black : AppStyle.accentColor)
                                    
                                    // 2. NOM
                                    Text(entry.username)
                                        .font(.subheadline)
                                        .fontWeight(isMe ? .black : .medium)
                                        .lineLimit(1)
                                        .foregroundColor(isMe ? .black : .white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // 3. ACTIONS
                                    HStack(spacing: 12) {
                                        if !isMe {
                                            // Méchanceté
                                            if data.isMechanceteUnlocked {
                                                attackMenu(for: entry)
                                            }
                                            
                                            // Gentillesse
                                            if data.isGentillesseUnlocked {
                                                giftMenu(for: entry)
                                            }
                                        }
                                    }
                                    
                                    // 4. SCORE
                                    Text("\(entry.score)")
                                        .font(.system(.subheadline, design: .monospaced))
                                        .fontWeight(.bold)
                                        .frame(width: 70, alignment: .trailing)
                                        .foregroundColor(isMe ? .black : .white)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 15)
                                .background(isMe ? AppStyle.accentColor : AppStyle.listRowBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isMe ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
                                )
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
    
    // MARK: - MENU ATTAQUE
    @ViewBuilder
    private func attackMenu(for entry: LeaderboardEntry) -> some View {
        Menu {
            if ownedAttacks.isEmpty {
                Text("Aucune arme en stock").foregroundColor(.gray)
            } else {
                ForEach(ownedAttacks, id: \.name) { attack in // Utilisation de .name comme ID stable
                    Button {
                        socialManager.sendAttack(
                            targetID: entry.id,
                            item: attack,
                            myName: gameManager.username
                        )
                        data.itemLevels[attack.name, default: 0] -= 1
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } label: {
                        Label("\(attack.name) \(attack.emoji)", systemImage: "bolt.fill")
                    }
                }
            }
        } label: {
            Image(systemName: "bolt.circle.fill")
                .font(.title3)
                .foregroundColor(.red)
                .opacity(ownedAttacks.isEmpty ? 0.4 : 1.0)
        }
    }

    // MARK: - MENU OFFRIR
    @ViewBuilder
    private func giftMenu(for entry: LeaderboardEntry) -> some View {
        Menu {
            if ownedGifts.isEmpty {
                Text("Aucun cadeau en stock").foregroundColor(.gray)
            } else {
                ForEach(ownedGifts, id: \.name) { gift in // Utilisation de .name comme ID stable
                    Button {
                        socialManager.sendGift(
                            targetID: entry.id,
                            item: gift,
                            myName: gameManager.username
                        )
                        data.itemLevels[gift.name, default: 0] -= 1
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } label: {
                        Label("\(gift.name) \(gift.emoji)", systemImage: "gift.fill")
                    }
                }
            }
        } label: {
            Image(systemName: "gift.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
                .opacity(ownedGifts.isEmpty ? 0.4 : 1.0)
        }
    }
}
