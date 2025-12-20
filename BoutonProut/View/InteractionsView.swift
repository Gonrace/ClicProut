import SwiftUI

struct InteractionsView: View {
    @ObservedObject var data: GameData
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    
    // États pour les alertes de combat
    @State private var combatAlertMessage: String = ""
    @State private var showCombatAlert: Bool = false
    
    // États pour le Hub Social
    @State private var selectedTab = 0 // 0 = Guerre, 1 = Cadeaux
    @State private var selectedPlayerID: String? = nil // Cible de l'action
    
    var body: some View {
        ZStack {
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Barre de titre
                CustomTitleBar(title: selectedTab == 0 ? "Centre de Combat ⚔️" : "Boutique Cadeaux 🎁", onDismiss: { dismiss() })
                
                // --- LE SÉLECTEUR D'ONGLETS ---
                Picker("", selection: $selectedTab) {
                    Text("⚔️ Guerre").tag(0)
                    if data.isGentillesseUnlocked {
                        Text("🎁 Cadeaux").tag(1)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                ScrollView {
                    VStack(spacing: 25) {
                        
                        if selectedTab == 0 {
                            // ==========================================
                            // ONGLET 0 : GUERRE (TON CODE ORIGINAL)
                            // ==========================================
                            
                            // SECTION 1 : ALERTES (ATTAQUES SUBIES)
                            threatsSection
                            
                            // SECTION 2 : ARSENAL D'ATTAQUE
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Arsenal d'Attaque 🧨").font(.headline).foregroundColor(.white)
                                ForEach(2...5, id: \.self) { acteNum in
                                    if data.isActeUnlocked(acteNum) {
                                        let items = data.allItems.filter { $0.category == .perturbateur && $0.acte == acteNum }
                                        if !items.isEmpty {
                                            Text("Objets de l'Acte \(acteNum)").font(.caption).foregroundColor(.gray)
                                            ForEach(items, id: \.name) { item in
                                                CombatItemRow(item: item, data: data, gameManager: gameManager)
                                            }
                                        }
                                    }
                                }
                            }

                            // SECTION 3 : ÉQUIPEMENT DE DÉFENSE
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Équipement de Défense 🛡️").font(.headline).foregroundColor(.white)
                                ForEach(2...5, id: \.self) { acteNum in
                                    if data.isActeUnlocked(acteNum) {
                                        let items = data.allItems.filter { $0.category == .defense && $0.acte == acteNum }
                                        if !items.isEmpty {
                                            Text("Objets de l'Acte \(acteNum)").font(.caption).foregroundColor(.gray)
                                            ForEach(items, id: \.name) { item in
                                                CombatItemRow(item: item, data: data, gameManager: gameManager)
                                            }
                                        }
                                    }
                                }
                            }
                            
                        } else {
                            // ==========================================
                            // ONGLET 1 : LA BOUTIQUE CADEAUX
                            // ==========================================
                            VStack(alignment: .leading, spacing: 20) {
                                Text("1. À qui faire plaisir ?").font(.headline).foregroundColor(.white)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(gameManager.leaderboard.filter { $0.id != gameManager.userID }) { player in
                                            VStack {
                                                Button(action: { selectedPlayerID = player.id }) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(selectedPlayerID == player.id ? AppStyle.accentColor : Color.white.opacity(0.1))
                                                            .frame(width: 50, height: 50)
                                                        Text(player.username.prefix(1).uppercased())
                                                            .foregroundColor(selectedPlayerID == player.id ? .black : .white)
                                                            .fontWeight(.bold)
                                                    }
                                                }
                                                Text(player.username).font(.system(size: 10)).foregroundColor(selectedPlayerID == player.id ? AppStyle.accentColor : .gray).lineLimit(1)
                                            }.frame(width: 65)
                                        }
                                    }
                                }
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                if let targetID = selectedPlayerID {
                                    let targetName = gameManager.leaderboard.first(where: { $0.id == targetID })?.username ?? ""
                                    Text("2. Cadeaux pour \(targetName)").font(.subheadline).foregroundColor(.gray)
                                    
                                    let gifts = data.allItems.filter { $0.category == .kado }
                                    ForEach(gifts) { gift in
                                        GiftShopRow(gift: gift, data: data, gameManager: gameManager, targetID: targetID)
                                    }
                                } else {
                                    Text("Sélectionne un ami ci-dessus").foregroundColor(.gray).frame(maxWidth: .infinity).padding(.top, 40)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // L'alerte personnalisée (Ton code original)
            if showCombatAlert {
                combatResultOverlay
            }
        }
    }
    
    // MARK: - COMPOSANTS INTERNES
    
    private var threatsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Menaces Actuelles").font(.headline).foregroundColor(.white)
            if data.currentAttacks.isEmpty {
                HStack {
                    Image(systemName: "shield.checkered").foregroundColor(.green).font(.title)
                    Text("Aucune menace détectée.").foregroundColor(.gray)
                }
                .padding().frame(maxWidth: .infinity).background(AppStyle.listRowBackground).cornerRadius(12)
            } else {
                ForEach(data.currentAttacks) { attack in
                    threatRow(attack: attack)
                }
            }
        }
    }
    
    private func threatRow(attack: ActiveAttackInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("⚠️ ALERTE ATTAQUE").fontWeight(.black).foregroundColor(.red)
                Spacer()
                Text(attack.expiryDate, style: .timer).foregroundColor(.yellow)
            }
            Text("\(attack.attackerName) utilise : \(attack.weaponName)").foregroundColor(.white)
            
            let ownedDefenses = data.allItems.filter { $0.category == .defense && data.itemLevels[$0.name, default: 0] > 0 }
            if !ownedDefenses.isEmpty {
                ForEach(ownedDefenses, id: \.name) { def in
                    Button(action: {
                        withAnimation {
                            self.combatAlertMessage = data.tryDefend(with: def)
                            self.showCombatAlert = true
                        }
                    }) {
                        Text("🛡️ Utiliser \(def.name)").padding(10).frame(maxWidth: .infinity).background(Color.blue).foregroundColor(.white).cornerRadius(8)
                    }
                }
            }
        }
        .padding().background(Color.red.opacity(0.15)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red, lineWidth: 1))
    }
    
    private var combatResultOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text(combatAlertMessage).font(.body).multilineTextAlignment(.center).foregroundColor(.white)
                Button("OK") { withAnimation { showCombatAlert = false } }
                    .padding().frame(width: 100).background(Color.orange).cornerRadius(10)
            }
            .padding(25).background(Color(red: 0.15, green: 0.2, blue: 0.25)).cornerRadius(20)
        }.zIndex(100)
    }
}

// MARK: - COMPOSANT LIGNE BOUTIQUE CADEAUX
struct GiftShopRow: View {
    let gift: ShopItem
    @ObservedObject var data: GameData
    @ObservedObject var gameManager: GameManager
    let targetID: String
    
    var body: some View {
        let cost = gift.baseCost
        let canAfford = gift.currency == .pets ? data.totalFartCount >= cost : data.goldenToiletPaper >= cost
        
        HStack {
            Text(gift.emoji).font(.title)
            VStack(alignment: .leading) {
                Text(gift.name).foregroundColor(.white).bold()
                Text(gift.description).font(.system(size: 10)).foregroundColor(.gray)
            }
            Spacer()
            Button(action: {
                if gift.currency == .pets { data.totalFartCount -= cost }
                else { data.goldenToiletPaper -= cost }
                gameManager.sendGift(targetUserID: targetID, giftItem: gift, senderUsername: gameManager.username)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }) {
                Text("\(cost) \(gift.currency == .goldenPaper ? "👑" : "💩")")
                    .padding(8).background(canAfford ? Color.green : Color.gray).foregroundColor(canAfford ? .black : .white).cornerRadius(8)
            }
            .disabled(!canAfford)
        }.padding(10).background(AppStyle.listRowBackground).cornerRadius(10)
    }
}

// MARK: - COMPOSANT LIGNE D'OBJET (Arsenal/Défense)
struct CombatItemRow: View {
    let item: ShopItem
    @ObservedObject var data: GameData
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        HStack {
            Text(item.emoji).font(.title)
            VStack(alignment: .leading) {
                Text(item.name).foregroundColor(.white).bold()
                Text(item.description).font(.system(size: 10)).foregroundColor(.gray).lineLimit(2)
            }
            Spacer()
            
            let isOwned = data.itemLevels[item.name, default: 0] > 0
            let canAfford = item.currency == .pets ? data.totalFartCount >= item.baseCost : data.goldenToiletPaper >= item.baseCost

            Button(action: {
                _ = data.attemptPurchase(item: item)
            }) {
                HStack(spacing: 4) {
                    if isOwned { Text("POSSÉDÉ ✅") }
                    else {
                        Text("\(item.baseCost)")
                        Text(item.currency == .goldenPaper ? "👑" : "💩")
                    }
                }
                .font(.caption).bold().padding(8)
                .background(isOwned ? Color.gray.opacity(0.3) : (canAfford ? Color.orange : Color.gray))
                .foregroundColor(canAfford ? .black : .white).cornerRadius(8)
            }
            .disabled(isOwned || !canAfford)
        }.padding(10).background(AppStyle.listRowBackground).cornerRadius(10)
    }
}
