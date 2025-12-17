
import SwiftUI

struct DebugView: View {
    @ObservedObject var data: GameData
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                Text("⚠️ Outils de Débogage ⚠️")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                // --- Tricherie ---
                
                Button("Ajouter 1 Milliard de Pets 💩") {
                    data.addCheatPets()
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
                
                Button("Ajouter 999 PQ d'Or 👑") {
                    data.addCheatGoldenPaper()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                
                Divider()
                    .padding(.vertical, 10)
                                
                Button("Simuler Attaque Reçue (5 min)") {
                    // On appelle directement la fonction de GameData
                    let _ = data.applyAttack(effectID: "attack_dps_reduction_50", duration: 5)
                }
                .tint(.purple)
                
                // --- Réinitialisation ---

                // Dans ta DebugView.swift
                Button(role: .destructive, action: {
                    data.hardReset()
                    // Optionnel : fermer le menu debug après le reset
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("RÉINITIALISATION TOTALE (WIPE)")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
            }
            .padding()
            .navigationTitle("DEBUG")
            .navigationBarItems(trailing: Button("Fermer") { dismiss() })
        }
    }
}
