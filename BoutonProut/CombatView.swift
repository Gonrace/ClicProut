import SwiftUI

struct CombatView: View {
    @ObservedObject var data: GameData
    @Environment(\.dismiss) var dismiss
    
    // États pour les alertes de combat
    @State private var combatAlertMessage: String = ""
    @State private var showCombatAlert: Bool = false
    
    var body: some View {
        ZStack {
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Barre de titre
                CustomTitleBar(title: "Centre de Combat ⚔️", onDismiss: { dismiss() })
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // --- SECTION 1 : ALERTES (ATTAQUES SUBIES) ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Menaces Actuelles").font(.headline).foregroundColor(.white)
                            
                            if data.currentAttacks.isEmpty {
                                HStack {
                                    Image(systemName: "shield.checkered").foregroundColor(.green).font(.title)
                                    Text("Aucune menace détectée.").foregroundColor(.gray)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(AppStyle.listRowBackground)
                                .cornerRadius(12)
                            } else {
                                ForEach(data.currentAttacks) { attack in
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("⚠️ ALERTE ATTAQUE").fontWeight(.black).foregroundColor(.red)
                                            Spacer()
                                            Text(attack.expiryDate, style: .timer)
                                                .font(.system(.body, design: .monospaced)).foregroundColor(.yellow)
                                        }
                                        
                                        Text("\(attack.attackerName) utilise : \(attack.weaponName)")
                                            .font(.subheadline).foregroundColor(.white)

                                        Divider().background(Color.white.opacity(0.2))

                                        // Liste des défenses possédées par le joueur
                                        let ownedDefenses = data.allItems.filter {
                                            $0.category == .defense && data.itemLevels[$0.name, default: 0] > 0
                                        }
                                        
                                        if ownedDefenses.isEmpty {
                                            Text("Aucune défense en stock !")
                                                .font(.caption).foregroundColor(.orange).italic()
                                        } else {
                                            Text("Choisir un objet pour contrer :").font(.caption).foregroundColor(.gray)
                                            
                                            ForEach(ownedDefenses, id: \.name) { defenseItem in
                                                Button(action: {
                                                    self.combatAlertMessage = data.tryDefend(with: defenseItem)
                                                    self.showCombatAlert = true
                                                    
                                                    if combatAlertMessage.contains("réussie") {
                                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                                    } else {
                                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                                    }
                                                }) {
                                                    HStack {
                                                        Text(defenseItem.emoji)
                                                        Text("Utiliser \(defenseItem.name)")
                                                        Spacer()
                                                        Image(systemName: "chevron.right")
                                                    }
                                                    .padding(10)
                                                    .background(Color.blue.opacity(0.8))
                                                    .foregroundColor(.white)
                                                    .cornerRadius(8)
                                                }
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color.red.opacity(0.15))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red, lineWidth: 1))
                                }
                            }
                        }

                        // --- SECTION 2 : ARSENAL D'ATTAQUE (Filtré par Actes débloqués) ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Arsenal d'Attaque 🧨").font(.headline).foregroundColor(.white)
                            
                            // On boucle de l'acte 2 (début pvp) à 5
                            ForEach(2...5, id: \.self) { acteNum in
                                if data.isActeUnlocked(acteNum) {
                                    let items = data.allItems.filter { $0.category == .perturbateur && $0.acte == acteNum }
                                    if !items.isEmpty {
                                        Text("Objets de l'Acte \(acteNum)").font(.caption).foregroundColor(.gray)
                                        ForEach(items, id: \.name) { item in
                                            CombatItemRow(item: item, data: data)
                                        }
                                    }
                                }
                            }
                        }

                        // --- SECTION 3 : ÉQUIPEMENT DE DÉFENSE (Filtré par Actes débloqués) ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Équipement de Défense 🛡️").font(.headline).foregroundColor(.white)
                            
                            ForEach(2...5, id: \.self) { acteNum in
                                if data.isActeUnlocked(acteNum) {
                                    let items = data.allItems.filter { $0.category == .defense && $0.acte == acteNum }
                                    if !items.isEmpty {
                                        Text("Objets de l'Acte \(acteNum)").font(.caption).foregroundColor(.gray)
                                        ForEach(items, id: \.name) { item in
                                            CombatItemRow(item: item, data: data)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .alert(isPresented: $showCombatAlert) {
            Alert(
                title: Text("Combat"),
                message: Text(combatAlertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - COMPOSANT LIGNE D'OBJET (Défini ici pour corriger l'erreur "In Scope")
struct CombatItemRow: View {
    let item: ShopItem
    @ObservedObject var data: GameData
    
    var body: some View {
        HStack {
            Text(item.emoji).font(.title)
            VStack(alignment: .leading) {
                Text(item.name).foregroundColor(.white).bold()
                Text(item.description).font(.system(size: 10)).foregroundColor(.gray).lineLimit(2)
            }
            Spacer()
            
            let isOwned = data.itemLevels[item.name, default: 0] > 0
            let cost = item.baseCost
            let canAfford = item.currency == .pets ? data.totalFartCount >= cost : data.goldenToiletPaper >= cost

            Button(action: {
                if data.attemptPurchase(item: item) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }) {
                HStack(spacing: 4) {
                    if isOwned {
                        Text("POSSÉDÉ ✅")
                    } else {
                        Text("\(cost)")
                        Text(item.currency == .goldenPaper ? "👑" : "💩")
                    }
                }
                .font(.caption).bold()
                .padding(8)
                .background(isOwned ? Color.gray.opacity(0.3) : (canAfford ? Color.orange : Color.gray.opacity(0.5)))
                .foregroundColor(isOwned ? .white.opacity(0.5) : (canAfford ? .black : .white.opacity(0.6)))
                .cornerRadius(8)
            }
            .disabled(isOwned || !canAfford)
        }
        .padding(10)
        .background(AppStyle.listRowBackground)
        .cornerRadius(10)
    }
}
