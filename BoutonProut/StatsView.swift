import SwiftUI
import UIKit

// NOTE: Les classes GameData et GameManager doivent exister.
// NOTE: Le style AppStyle et la structure CustomTitleBar doivent être définis.

// --- STRUCTURES D'AIDE ---

// Ligne d'affichage pour les statistiques
struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(AppStyle.accentColor)
        }
        .foregroundColor(.white)
        .padding(.vertical, 5)
    }
}


// --- VUE PRINCIPALE ---

struct StatsView: View {
    @ObservedObject var data: GameData
    @ObservedObject var gameManager: GameManager
    
    @Environment(\.dismiss) var dismiss
    
    @State private var showingNameEditAlert = false
    @State private var tempUsername: String = ""
    
    // État pour la vue de débogage
    @State private var showingDebug = false
    
    var body: some View {
        ZStack {
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // 1. BARRE DE TITRE (Style unifié)
                CustomTitleBar(title: "Statistiques 📊", onDismiss: { dismiss() })
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppStyle.defaultPadding) {
                        
                        // Section 1: Profil
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Profil").font(AppStyle.subTitleFont).foregroundColor(.white)
                            
                            // Rangée d'édition du nom
                            HStack {
                                Text("Nom de Prouteur :")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(gameManager.username)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppStyle.accentColor)
                                
                                // BOUTON MODIFIER
                                Button {
                                    tempUsername = gameManager.username
                                    showingNameEditAlert = true
                                } label: {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title2)
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(.orange)
                            }
                            .padding(AppStyle.defaultPadding / 2)
                            .background(AppStyle.listRowBackground)
                            .cornerRadius(10)
                        }
                        
                        // Section 2: Statistiques de base
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Données de Jeu").font(AppStyle.subTitleFont).foregroundColor(.white)
                            
                            VStack(spacing: 1) {
                                StatRow(title: "Pets Totaux", value: "\(data.totalFartCount)")
                                StatRow(title: "Pets générés (à vie)", value: "\(data.lifetimeFarts)")
                                StatRow(title: "Pets par Clic Max", value: "\(data.clickPower)")
                                StatRow(title: "Pets par Seconde Max", value: String(format: "%.2f", data.petsPerSecond))
                            }
                            .background(AppStyle.listRowBackground)
                            .cornerRadius(10)
                        }
                        
                        // --- AJOUT : SECTION OUTILS DE DÉBOGAGE (Bouton d'accès en bas) ---
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Outils Avancés (DEV)").font(AppStyle.subTitleFont).foregroundColor(.red)
                            
                            Button("Accéder aux Outils de Test et Réinitialisation") {
                                showingDebug = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.3))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                        }
                        
                    }
                    .padding(AppStyle.defaultPadding)
                }
            }
        }
        
        // POP-UP d'édition de nom
        .alert("Modifier votre Nom", isPresented: $showingNameEditAlert) {
            TextField("Nouveau nom", text: $tempUsername)
            
            Button("Valider") {
                let trimmedName = tempUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else { return }
                gameManager.saveNewUsername(trimmedName, lifetimeScore: data.totalFartCount)
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Entrez le nouveau nom que vous souhaitez afficher dans le classement.")
        }
        
        // AFFICHAGE DE LA VUE DE DÉBOGAGE
        .sheet(isPresented: $showingDebug) {
            DebugView(data: data)
        }
    }
}
