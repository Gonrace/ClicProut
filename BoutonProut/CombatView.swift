import SwiftUI

struct CombatView: View {
    @ObservedObject var data: GameData
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Barre de titre avec bouton retour
                CustomTitleBar(title: "Centre de Combat ⚔️", onDismiss: { dismiss() })
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // --- SECTION 1 : ÉTAT DES ATTAQUES SUBIES (DÉFENSE ACTIVE) ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Statut de Défense").font(.headline).foregroundColor(.white)
                            
                            if data.currentAttacks.isEmpty {
                                HStack {
                                    Image(systemName: "shield.checkered").foregroundColor(.green).font(.title)
                                    Text("Aucune menace détectée.").foregroundColor(.gray)
                                }
                                .padding().frame(maxWidth: .infinity).background(AppStyle.listRowBackground).cornerRadius(12)
                            } else {
                                ForEach(data.currentAttacks) { attack in
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Text("⚠️ ALERTE ATTAQUE").fontWeight(.black).foregroundColor(.red)
                                            Spacer()
                                            // Compteur de temps réel avant expiration
                                            Text(attack.expiryDate, style: .timer)
                                                .font(.system(.body, design: .monospaced)).foregroundColor(.yellow)
                                        }
                                        Text("\(attack.attackerName) vous bombarde avec : \(attack.weaponName)")
                                            .font(.subheadline).foregroundColor(.white)
                                        
                                        // Utilisation d'un consommable de défense (ex: Bouchon)
                                        if data.itemLevels["Bouchon de Fesses", default: 0] > 0 {
                                            Button(action: {
                                                data.activeAttacks.removeValue(forKey: attack.id)
                                                data.itemLevels["Bouchon de Fesses", default: 0] -= 1
                                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                            }) {
                                                Label("Utiliser Bouchon (Stock: \(data.itemLevels["Bouchon de Fesses", default: 0]))", systemImage: "shield.fill")
                                                    .frame(maxWidth: .infinity).padding(10).background(Color.green).foregroundColor(.white).cornerRadius(8)
                                            }
                                        }
                                    }
                                    .padding().background(Color.red.opacity(0.15)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red, lineWidth: 1))
                                }
                            }
                        }

                        // --- SECTION 2 : ARMURERIE (ACHATS COMBAT) ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Armurerie & Défense 🛒").font(.headline).foregroundColor(.white)
                            
                            // Filtrage des objets de catégorie Combat uniquement
                            let combatShopItems = data.allItems.filter { $0.category == .perturbateur || $0.category == .defense }
                            
                            ForEach(combatShopItems, id: \.id) { item in
                                HStack {
                                    Text(item.emoji).font(.title)
                                    VStack(alignment: .leading) {
                                        Text(item.name).foregroundColor(.white).bold()
                                        Text(item.description).font(.system(size: 10)).foregroundColor(.gray).lineLimit(2)
                                    }
                                    Spacer()
                                    
                                    // Variables de contrôle pour l'affichage du bouton
                                    let isOwned = data.itemLevels[item.name, default: 0] > 0
                                    let isDefense = item.category == .defense
                                    let cost = item.baseCost
                                    
                                    // Vérification du solde (Pets ou PQ d'Or)
                                    let canAfford = item.currency == .pets ? data.totalFartCount >= cost : data.goldenToiletPaper >= cost

                                    Button(action: {
                                        if data.attemptPurchase(item: item) {
                                            // Vibration Succès
                                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        } else {
                                            // Vibration Erreur (pas assez d'argent)
                                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            if isOwned && isDefense {
                                                Text("POSSÉDÉ ✅")
                                            } else {
                                                Text("\(cost)")
                                                Text(item.currency == .goldenPaper ? "👑" : "💩")
                                            }
                                        }
                                        .font(.caption).bold()
                                        .padding(8)
                                        // LOGIQUE DE COULEUR : Orange si achetable, Gris si bloqué ou déjà possédé
                                        .background(isOwned && isDefense ? Color.gray.opacity(0.3) : (canAfford ? Color.orange : Color.gray.opacity(0.5)))
                                        .foregroundColor(isOwned && isDefense ? .white.opacity(0.5) : (canAfford ? .black : .white.opacity(0.6)))
                                        .cornerRadius(8)
                                    }
                                    // Bloqué si défense déjà achetée OU si solde insuffisant
                                    .disabled((isOwned && isDefense) || !canAfford)
                                }
                                .padding(10).background(AppStyle.listRowBackground).cornerRadius(10)
                            }
                        }

                        // --- SECTION 3 : VOTRE ARSENAL (MUNITIONS EN STOCK) ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Votre Arsenal (Attaque)").font(.headline).foregroundColor(.white)
                            
                            let ownedWeapons = data.allItems.filter { $0.category == .perturbateur && data.itemLevels[$0.name, default: 0] > 0 }
                            
                            if ownedWeapons.isEmpty {
                                Text("Aucune arme en stock.").font(.caption).foregroundColor(.gray).padding()
                            } else {
                                ForEach(ownedWeapons, id: \.id) { weapon in
                                    HStack {
                                        Text(weapon.emoji)
                                        VStack(alignment: .leading) {
                                            Text(weapon.name).foregroundColor(.white).font(.subheadline)
                                            Text("Munitions: \(data.itemLevels[weapon.name, default: 0])").font(.caption2).foregroundColor(.gray)
                                        }
                                        Spacer()
                                        // Badge indiquant que l'arme peut être utilisée depuis le classement
                                        Text("PRÊT").font(.caption2).bold().padding(4).background(Color.blue).cornerRadius(4).foregroundColor(.white)
                                    }
                                    .padding().background(Color.white.opacity(0.05)).cornerRadius(10)
                                }
                            }
                        }
                        
                        Text("Pour lancer une attaque, rendez-vous dans le Classement 🏆")
                            .font(.caption2).foregroundColor(.gray).multilineTextAlignment(.center).padding(.top, 10)
                    }
                    .padding()
                }
            }
        }
    }
}
