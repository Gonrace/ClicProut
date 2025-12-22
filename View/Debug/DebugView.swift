import SwiftUI

struct DebugView: View {
    @ObservedObject var data: GameData
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // --- 1. RESSOURCES ---
                Section("Monnaies") {
                    Button("💰 +1 Million Pets") { data.totalFartCount += 1_000_000 }
                    Button("👑 +1 000 PQ d'Or") { data.goldenToiletPaper += 1000 }
                }
                
                // --- 2. PROGRESSION & ACTES ---
                Section("Actes") {
                    HStack {
                        ForEach(1...5, id: \.self) { acte in
                            Button("A\(acte)") { unlockActe(acte) }
                                .buttonStyle(.bordered)
                        }
                    }
                }
                
                // --- 3. INVENTAIRE RAPIDE (Attaque & Défense) ---
                Section("Donner Objets (x10)") {
                    Button("🛡️ Toutes les Défenses") { giveAll(of: .defense) }
                    Button("🧨 Toutes les Attaques") { giveAll(of: .perturbateur) }
                }

                // --- 4. SIMULATEUR : S'ENVOYER UNE ATTAQUE ---
                Section("S'attaquer soi-même") {
                    let attacks = data.cloudManager?.allItems.filter { $0.category == .perturbateur } ?? []
                    ForEach(attacks, id: \.name) { item in
                        Button("\(item.emoji) Recevoir \(item.name)") {
                            data.applyAttack(
                                effectID: item.effectID ?? "",
                                duration: (item.durationSec > 0 ? item.durationSec / 60 : 5),
                                attackerName: "Moi-même",
                                weaponName: item.name
                            )
                        }
                    }
                    Button("🧹 Stopper toutes les attaques") { data.activeAttacks.removeAll() }
                        .foregroundColor(.green)
                }
                
                // --- 5. RESET ---
                Section("Danger") {
                    Button(role: .destructive) {
                        data.hardReset()
                        dismiss()
                    } label: {
                        Label("RÉINITIALISER TOUT", systemImage: "trash.fill")
                    }
                }
            }
            .navigationTitle("Menu Dev 🛠️")
            .navigationBarItems(trailing: Button("Fermer") { dismiss() })
        }
    }
    
    // --- LOGIQUE DE TRICHE ---
    
    func unlockActe(_ num: Int) {
        // Donne 1 exemplaire de chaque objet de l'acte visé pour le débloquer instantanément
        let items = data.cloudManager?.allItems ?? []
        items.filter { $0.acte == num }.forEach { data.itemLevels[$0.name] = 1 }
    }
    
    func giveAll(of category: ItemCategory) {
        // Donne 10 exemplaires de chaque objet d'une catégorie (utile pour les consos)
        let items = data.cloudManager?.allItems ?? []
        items.filter { $0.category == category }.forEach {
            data.itemLevels[$0.name, default: 0] += 10
        }
    }
}
