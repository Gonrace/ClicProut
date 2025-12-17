import SwiftUI
import UIKit

// MARK: - COMPOSANTS D'AFFICHAGE

/// Ligne réutilisable pour afficher une statistique (Titre à gauche, Valeur à droite)
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
        .padding(.vertical, 8) // Un peu plus d'espace pour la lisibilité
        .padding(.horizontal, 10)
    }
}

// MARK: - VUE PRINCIPALE DES STATISTIQUES

struct StatsView: View {
    @ObservedObject var data: GameData
    @ObservedObject var gameManager: GameManager
    
    @Environment(\.dismiss) var dismiss
    
    // --- ÉTATS POUR LE PSEUDO ---
    @State private var showingNameEditAlert = false
    @State private var tempUsername: String = ""
    
    // --- ÉTATS POUR LE MENU DEBUG SECRET ---
    @State private var debugClickCount = 0       // Compteur de clics sur le titre
    @State private var showingCodeAlert = false   // Affiche la demande de mot de passe
    @State private var secretCodeInput = ""       // Stocke la saisie du code
    @State private var showingDebug = false       // Contrôle l'ouverture du DebugView
    
    var body: some View {
        ZStack {
            // Fond d'écran sombre unifié
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                
                // 1. BARRE DE TITRE AVEC DÉTECTION DE CLICS (SECRET)
                // Cliquer 10 fois ici pour déclencher l'accès DEV
                CustomTitleBar(title: "Statistiques 📊", onDismiss: { dismiss() })
                    .contentShape(Rectangle()) // Rend toute la zone cliquable
                    .onTapGesture {
                        debugClickCount += 1
                        if debugClickCount >= 10 {
                            showingCodeAlert = true
                            debugClickCount = 0 // Réinitialise pour la prochaine fois
                        }
                    }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppStyle.defaultPadding) {
                        
                        // --- SECTION 1 : PROFIL ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Profil").font(AppStyle.subTitleFont).foregroundColor(.white)
                            
                            HStack {
                                Text("Pseudo :").foregroundColor(.white)
                                Spacer()
                                Text(gameManager.username)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppStyle.accentColor)
                                
                                // Bouton pour modifier le pseudo
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
                        
                        // --- SECTION 2 : DONNÉES DE JEU ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Données de Jeu").font(AppStyle.subTitleFont).foregroundColor(.white)
                            
                            VStack(spacing: 0) {
                                StatRow(title: "Pets Actuels", value: "\(data.totalFartCount) 💩")
                                Divider().background(Color.white.opacity(0.1)) // Ligne de séparation légère
                                StatRow(title: "Pets à vie (Score)", value: "\(data.lifetimeFarts) 🏆")
                                Divider().background(Color.white.opacity(0.1))
                                StatRow(title: "Puissance Clic", value: "\(data.clickPower) PPC")
                                Divider().background(Color.white.opacity(0.1))
                                StatRow(title: "Production Auto", value: String(format: "%.2f PPS", data.petsPerSecond))
                            }
                            .background(AppStyle.listRowBackground)
                            .cornerRadius(10)
                        }
                        
                        // Note informative en bas
                        Text("Les 'Pets à vie' déterminent votre rang dans le classement mondial.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                    }
                    .padding(AppStyle.defaultPadding)
                }
            }
        }
        
        // --- ALERTES ET MODALES ---

        // 1. Alerte Modification de Pseudo
        .alert("Modifier votre Nom", isPresented: $showingNameEditAlert) {
            TextField("Nouveau nom", text: $tempUsername)
                .textInputAutocapitalization(.words)
            
            Button("Valider") {
                let trimmed = tempUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    gameManager.saveNewUsername(trimmed, lifetimeScore: data.lifetimeFarts)
                }
            }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Choisissez le nom qui apparaîtra aux yeux de tous dans le classement.")
        }
        
        // 2. Alerte de Code Secret (Déclenchée par 10 clics sur le titre)
        .alert("Accès Développeur", isPresented: $showingCodeAlert) {
            TextField("Entrez le code", text: $secretCodeInput)
                .textInputAutocapitalization(.characters) // Force les majuscules
            
            Button("Valider") {
                if secretCodeInput == "PROUT2025" {
                    showingDebug = true // Ouvre le menu de test
                }
                secretCodeInput = "" // Nettoyage
            }
            Button("Annuler", role: .cancel) {
                secretCodeInput = ""
            }
        } message: {
            Text("Veuillez saisir le code d'accès pour les outils de débogage.")
        }
        
        // 3. Affichage du Menu Debug (si le code est bon)
        .sheet(isPresented: $showingDebug) {
            DebugView(data: data)
                .interactiveDismissDisabled(true) // Empêche de fermer par erreur pendant un test
        }
    }
}
