import SwiftUI

struct InteractionsView: View {
    @ObservedObject var data: GameData
    @ObservedObject var gameManager: GameManager
    @ObservedObject var socialManager: SocialManager
    @Environment(\.dismiss) var dismiss
    
    // États pour les alertes de combat
    @State private var combatAlertMessage: String = ""
    @State private var showCombatAlert: Bool = false
    
    // État pour le Hub Social
    @State private var selectedTab = 0 // 0 = Attaquer, 1 = Offrir
    
    var body: some View {
        ZStack {
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 1. BARRE DE TITRE FIXE
                CustomTitleBar(title: "WC Publics 🚽", onDismiss: { dismiss() })
                                
                // 2. SOUS-TITRE DYNAMIQUE (Optionnel, pour le style)
                if data.hasDiscoveredInteractions {
                    Text(selectedTab == 0 ? "ZONE DE GUERRE ⚔️" : "SERVICE DE DON 🎁")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(selectedTab == 0 ? .red : .green)
                        .padding(.bottom, 5)
                }

                // 2. VÉRIFICATION DE LA DÉCOUVERTE
                if !data.isMechanceteUnlocked && !data.isGentillesseUnlocked {
                    // --- ÉTAT VIDE : WC PUBLICS DÉCOUVERTS MAIS INUTILISABLES ---
                    VStack(spacing: 25) {
                        Spacer()
                            
                        // Icône thématique
                        Text("🚽")
                            .font(.system(size: 80))
                            .shadow(radius: 10)
                            
                        VStack(spacing: 15) {
                            Text("Vous venez de débloquer les WC Publics !")
                                .font(.title3)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                                
                            Text("C'est ici que l'on interagit avec les autres prouteurs, mais vous n'avez pas encore découvert comment vous y prendre...")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 40)
                        }
                            
                            // Petit indicateur visuel pour aider le joueur
                        Text("(Allez à la Boutique pour trouver de quoi vous occuper)")
                            .font(.caption)
                            .italic()
                            .foregroundColor(AppStyle.accentColor.opacity(0.7))
                            .padding(.top, 10)

                        Spacer()
                    }
                } else {
                    // --- INTERFACE DÉBLOQUÉE ---
                    
                    // On n'affiche le picker que si les DEUX sont débloqués
                    if data.isMechanceteUnlocked && data.isGentillesseUnlocked {
                        Picker("", selection: $selectedTab) {
                            Text("⚔️ Attaquer").tag(0)
                            Text("🎁 Offrir").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                    }

                    ScrollView {
                        VStack(spacing: 25) {
                            
                            if selectedTab == 0 && data.isMechanceteUnlocked {
                                // ==========================================
                                // ONGLET : ATTAQUER (GUERRE)
                                // ==========================================
                                
                                // SECTION 1 : ALERTES (ATTAQUES SUBIES)
                                threatsSection // Ton composant existant pour les attaques
                                
                                // SECTION 2 : BOUTIQUE ARSENAL
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Boutique d'Arsenal 🧨").font(.headline).foregroundColor(.white)
                                    Text("Achetez des armes pour les utiliser dans le Classement.").font(.caption).foregroundColor(.gray)
                                    
                                    ForEach(2...5, id: \.self) { acteNum in
                                        if data.isActeUnlocked(acteNum) {
                                            let items = data.cloudManager?.allItems.filter { $0.category == .perturbateur && $0.acte == acteNum } ?? []
                                            if !items.isEmpty {
                                                Text("Acte \(acteNum)").font(.caption).foregroundColor(.gray).padding(.top, 5)
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
                                            let items = data.cloudManager?.allItems.filter { $0.category == .defense && $0.acte == acteNum } ?? []
                                            if !items.isEmpty {
                                                ForEach(items, id: \.name) { item in
                                                    CombatItemRow(item: item, data: data, gameManager: gameManager)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            } else if selectedTab == 1 && data.isGentillesseUnlocked {
                                // ==========================================
                                // ONGLET : OFFRIR (CADEAUX)
                                // ==========================================
                                
                                // SECTION 1 : HISTORIQUE DES CADEAUX REÇUS (Symétrique aux Menaces)
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Cadeaux reçus 🎁").font(.headline).foregroundColor(.white)
                                    
                                    if data.receivedGifts.isEmpty {
                                        Text("Aucun cadeau reçu pour le moment.")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(12)
                                    } else {
                                        // On affiche les 5 derniers cadeaux reçus
                                        ForEach(data.receivedGifts.prefix(5)) { gift in
                                            HStack(spacing: 15) {
                                                Text(gift.emoji)
                                                    .font(.system(size: 30))
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(gift.senderName)
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(.green)
                                                    Text("t'a offert un(e) \(gift.giftName)")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white.opacity(0.8))
                                                }
                                                
                                                Spacer()
                                                
                                                Text(gift.date, style: .time)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.gray)
                                            }
                                            .padding(12)
                                            .background(Color.white.opacity(0.08))
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                                
                                // SECTION 2 : BOUTIQUE DE CADEAUX
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Boutique de Cadeaux 🎁").font(.headline).foregroundColor(.white)
                                    Text("Achetez un cadeau unique pour l'offrir depuis le Classement.").font(.caption).foregroundColor(.gray)
                                    let gifts = data.cloudManager?.allItems.filter { $0.category == .kado } ?? []
                                    if gifts.isEmpty {
                                        Text("Aucun cadeau disponible...").foregroundColor(.gray).padding()
                                    } else {
                                        ForEach(gifts) { gift in
                                            CombatItemRow(item: gift, data: data, gameManager: gameManager)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            
            if showCombatAlert {
                combatResultOverlay
            }
        }
        .onAppear {
            // Ajustement automatique de l'onglet au démarrage
            if !data.isMechanceteUnlocked && data.isGentillesseUnlocked {
                selectedTab = 1
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
        let allItems = data.cloudManager?.allItems ?? []
        let ownedDefenses = allItems.filter { $0.category == .defense && data.itemLevels[$0.name, default: 0] > 0 }
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("⚠️ ALERTE ATTAQUE").fontWeight(.black).foregroundColor(.red)
                Spacer()
                Text(attack.expiryDate, style: .timer).foregroundColor(.yellow)
            }
            Text("\(attack.attackerName) utilise : \(attack.weaponName)").foregroundColor(.white)
            
            let allItems = data.cloudManager?.allItems ?? []
            let ownedDefenses = allItems.filter { $0.category == .defense && data.itemLevels[$0.name, default: 0] > 0 }
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

// MARK: - COMPOSANT LIGNE D'OBJET (Arsenal/Défense/Cadeaux)
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
                    if isOwned {
                        Text("POSSÉDÉ ✅")
                    } else {
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
