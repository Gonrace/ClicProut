
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
                
                // --- Réinitialisation ---
                
                Button(role: .destructive) {
                    data.softReset()
                    // Si vous avez un timer dans ContentView, vous devez le réinitialiser après
                    // avoir appelé cette fonction (voir point 3 ci-dessous).
                    dismiss()
                } label: {
                    Text("RÉINITIALISER TOUT (Soft Reset)")
                        .padding(.horizontal, 20)
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
