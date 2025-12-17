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
        .padding(.vertical, 12) // Augmenté pour un look plus premium
        .padding(.horizontal, 15)
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
    @State private var debugClickCount = 0
    @State private var showingCodeAlert = false
    @State private var secretCodeInput = ""
    @State private var showingDebug = false
    
    // --- LOGIQUE NARRATIVE DES ACTES ---
    // Détermine le titre affiché selon l'acte le plus élevé débloqué
    var currentEvolutionStage: String {
        if data.isActeUnlocked(5) { return "Retraité Serein 👴" }
        if data.isActeUnlocked(4) { return "Cadre Dynamique 💼" }
        if data.isActeUnlocked(3) { return "Loveur Élégant ❤️" }
        if data.isActeUnlocked(2) { return "Ado Rebelle 😈" }
        return "Bébé Innocent 👶"
    }
    
    var body: some View {
        ZStack {
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                
                // 1. BARRE DE TITRE (Zone secrète pour le menu dev)
                CustomTitleBar(title: "Statistiques 📊", onDismiss: { dismiss() })
                    .contentShape(Rectangle())
                    .onTapGesture {
                        debugClickCount += 1
                        if debugClickCount >= 10 {
                            showingCodeAlert = true
                            debugClickCount = 0
                        }
                    }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        
                        // --- SECTION 1 : STADE D'ÉVOLUTION
                        VStack(spacing: 15) {
                            Text("TON STADE D'ÉVOLUTION")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            VStack(spacing: 12) {
                                Text(currentEvolutionStage)
                                    .font(.title3)
                                    .fontWeight(.black)
                                    .foregroundColor(AppStyle.accentColor)
                                
                                // --- BARRE DE PROGRESSION ---
                                VStack(spacing: 5) {
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            // Fond de la barre
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(Color.white.opacity(0.1))
                                                .frame(height: 8)
                                            
                                            // Remplissage
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(AppStyle.accentColor)
                                                .frame(width: geo.size.width * CGFloat(data.currentActeProgress), height: 8)
                                        }
                                    }
                                    .frame(height: 8)
                                    
                                    // Texte du pourcentage
                                    HStack {
                                        Text("Complétion de l'acte")
                                        Spacer()
                                        Text("\(Int(data.currentActeProgress * 100))%")
                                            .fontWeight(.bold)
                                    }
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(15)
                        }
                        .padding(.top, 10)
                        // --- SECTION 2 : PROFIL ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Profil").font(AppStyle.subTitleFont).foregroundColor(.white)
                            
                            HStack {
                                Image(systemName: "person.fill").foregroundColor(.gray)
                                Text("Pseudo :").foregroundColor(.white)
                                Spacer()
                                Text(gameManager.username)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppStyle.accentColor)
                                
                                Button {
                                    tempUsername = gameManager.username
                                    showingNameEditAlert = true
                                } label: {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding()
                            .background(AppStyle.listRowBackground)
                            .cornerRadius(12)
                        }
                        
                        // --- SECTION 3 : DONNÉES FINANCIÈRES ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Économie").font(AppStyle.subTitleFont).foregroundColor(.white)
                            
                            VStack(spacing: 0) {
                                StatRow(title: "Pets en poche", value: "\(data.totalFartCount) 💩")
                                Divider().background(Color.white.opacity(0.1))
                                StatRow(title: "PQ d'Or cumulé", value: "\(data.goldenToiletPaper) 👑")
                                Divider().background(Color.white.opacity(0.1))
                                StatRow(title: "Score Total (Vie)", value: "\(data.lifetimeFarts) 🏆")
                            }
                            .background(AppStyle.listRowBackground)
                            .cornerRadius(12)
                        }
                        
                        // --- SECTION 4 : PERFORMANCES ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Performances").font(AppStyle.subTitleFont).foregroundColor(.white)
                            
                            VStack(spacing: 0) {
                                StatRow(title: "Puissance de Clic", value: "\(data.clickPower) PPC")
                                Divider().background(Color.white.opacity(0.1))
                                StatRow(title: "Vitesse Auto", value: String(format: "%.2f PPS", data.petsPerSecond))
                            }
                            .background(AppStyle.listRowBackground)
                            .cornerRadius(12)
                        }
                        
                        // Footer
                        Text("Débloque de nouveaux objets dans la boutique pour évoluer vers l'âge suivant.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 10)
                    }
                    .padding(AppStyle.defaultPadding)
                }
            }
        }
        
        // --- ALERTES ---
        
        .alert("Modifier votre Nom", isPresented: $showingNameEditAlert) {
            TextField("Nouveau nom", text: $tempUsername)
            Button("Valider") {
                let trimmed = tempUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    gameManager.saveNewUsername(trimmed, lifetimeScore: data.lifetimeFarts)
                }
            }
            Button("Annuler", role: .cancel) { }
        }
        
        .alert("Accès Développeur", isPresented: $showingCodeAlert) {
            SecureField("Code secret", text: $secretCodeInput)
            Button("Valider") {
                if secretCodeInput == "PROUT2025" {
                    showingDebug = true
                }
                secretCodeInput = ""
            }
            Button("Annuler", role: .cancel) { secretCodeInput = "" }
        }
        
        .sheet(isPresented: $showingDebug) {
            DebugView(data: data)
        }
    }
}
