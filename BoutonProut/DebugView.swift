import SwiftUI

struct DebugView: View {
    @ObservedObject var data: GameData
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List { // Utilisation d'une List pour un look iOS natif et propre
                
                // --- SECTION 1 : RESSOURCES ---
                Section(header: Text("Économie & Monnaies")) {
                    HStack {
                        Button("Pets +1M") { data.totalFartCount += 1_000_000 }
                        Spacer()
                        Button("Pets +1B") { data.totalFartCount += 1_000_000_000 }
                    }
                    HStack {
                        Button("PQ Or +100") { data.goldenToiletPaper += 100 }
                        Spacer()
                        Button("PQ Or +1k") { data.goldenToiletPaper += 1000 }
                    }
                }
                
                // --- SECTION 2 : GESTION DES ACTES ---
                Section(header: Text("Progression par Actes")) {
                    Text("Débloquer jusqu'à :").font(.caption).foregroundColor(.gray)
                    HStack {
                        ForEach(2...5, id: \.self) { acte in
                            Button("Acte \(acte)") {
                                unlockUntilActe(acte)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                // --- SECTION 3 : SIMULATEUR DE COMBAT ---
                Section(header: Text("Simulateur de Combat (Reçevoir)")) {
                    Button("🧴 Spray (-50% PPS / 5min)") {
                        data.applyAttack(effectID: "attack_dps_reduction_50", duration: 5, attackerName: "DarkProuteur", weaponName: "Spray Désodorisant")
                    }
                    Button("😫 Burn-out (-90% Tout / 15min)") {
                        data.applyAttack(effectID: "attack_mega_nerf", duration: 15, attackerName: "Le Patron", weaponName: "Burn-out")
                    }
                    Button("📢 Dénonciation (Bloque Clic / 5min)") {
                        data.applyAttack(effectID: "attack_total_block", duration: 5, attackerName: "Voisin Relou", weaponName: "Dénonciation")
                    }
                    Button("🧹 Nettoyer toutes les attaques") {
                        data.activeAttacks.removeAll()
                    }.foregroundColor(.green)
                }
                
                // --- SECTION 4 : ÉQUIPEMENT RAPIDE ---
                Section(header: Text("Inventaire de triche")) {
                    Button("🎁 Pack Défense Complet (x1)") {
                        giveAllDefenses()
                    }
                    Button("🧨 Pack Attaque Complet (x1)") {
                        giveAllAttacks()
                    }
                }

                // --- SECTION 5 : SYSTÈME & RESET ---
                Section(header: Text("Danger Zone")) {
                    Button(role: .destructive) {
                        data.hardReset()
                        dismiss()
                    } label: {
                        Label("WIPE TOTAL (REMISE À ZÉRO)", systemImage: "trash.danger")
                    }
                }
            }
            .navigationTitle("Menu Dev")
            .navigationBarItems(trailing: Button("Fermer") { dismiss() })
        }
    }
    
    // MARK: - HELPERS DE TRICHE
    
    func unlockUntilActe(_ target: Int) {
        // Pour débloquer l'acte X, on donne 1 exemplaire de tous les objets des actes précédents
        let itemsToUnlock = data.allItems.filter { $0.acte < target }
        for item in itemsToUnlock {
            data.itemLevels[item.name] = 1
        }
        // Donner aussi un peu d'argent pour tester l'achat
        data.totalFartCount += 100_000
    }
    
    func giveAllDefenses() {
        let defenses = data.allItems.filter { $0.category == .defense }
        for item in defenses {
            data.itemLevels[item.name] = 1
        }
    }
    
    func giveAllAttacks() {
        let attacks = data.allItems.filter { $0.category == .perturbateur }
        for item in attacks {
            data.itemLevels[item.name] = 1
        }
    }
}
