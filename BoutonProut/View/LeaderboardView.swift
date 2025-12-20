import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var gameManager: GameManager
    @ObservedObject var data: GameData
    @Environment(\.dismiss) var dismiss
    
    // Filtre pour les attaques que l'on a déjà en stock
    var ownedAttacks: [ShopItem] {
        return data.allItems.filter { item in
            item.category == .perturbateur && data.itemLevels[item.name, default: 0] > 0
        }
    }
    
    // --- NOUVEAU : Liste de tous les cadeaux disponibles dans le Cloud ---
    var availableGifts: [ShopItem] {
        return data.allItems.filter { $0.category == .kado }
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
                                        // --- ATTAQUES (Si en stock) ---
                                        if !ownedAttacks.isEmpty && !isMe {
                                            attackMenu(for: entry)
                                        }
                                        
                                        // --- NOUVEAU : CADEAUX (Si Gentillesse débloquée) ---
                                        if data.isGentillesseUnlocked && !isMe {
                                            giftMenu(for: entry)
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
    
    // MARK: - MENU ATTAQUE (Existant)
    @ViewBuilder
    private func attackMenu(for entry: LeaderboardEntry) -> some View {
        Menu {
            ForEach(ownedAttacks, id: \.id) { attack in
                Button {
                    gameManager.sendAttack(
                        targetUserID: entry.id,
                        item: attack,
                        senderUsername: gameManager.username
                    )
                    data.itemLevels[attack.name] = 0 // Consomme l'objet
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } label: {
                    Label("\(attack.name) \(attack.emoji)", systemImage: "bolt.fill")
                }
            }
        } label: {
            Image(systemName: "bolt.circle.fill")
                .font(.title3)
                .foregroundColor(.red)
        }
    }
    
    // MARK: - NOUVEAU : COMPOSANT MENU CADEAU
    @ViewBuilder
    private func giftMenu(for entry: LeaderboardEntry) -> some View {
        Menu {
            Section("Offrir un cadeau à \(entry.username)") {
                ForEach(availableGifts, id: \.id) { gift in
                    let canAfford = gift.currency == .pets ? data.totalFartCount >= gift.baseCost : data.goldenToiletPaper >= gift.baseCost
                    
                    Button {
                        // 1. Déduction du prix
                        if gift.currency == .pets { data.totalFartCount -= gift.baseCost }
                        else { data.goldenToiletPaper -= gift.baseCost }
                        
                        // 2. Envoi via le GameManager (vers Firebase)
                        gameManager.sendGift(
                            targetUserID: entry.id,
                            giftItem: gift,
                            senderUsername: gameManager.username
                        )
                        
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } label: {
                        HStack {
                            Text("\(gift.emoji) \(gift.name)")
                            Spacer()
                            Text("\(gift.baseCost) \(gift.currency == .pets ? "💩" : "👑")")
                        }
                    }
                    .disabled(!canAfford) // On ne peut pas cliquer si on n'a pas assez de sous
                }
            }
        } label: {
            Image(systemName: "gift.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
        }
    }
}
