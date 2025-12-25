import SwiftUI
import FirebaseAuth

// MARK: - COMPOSANTS D'AFFICHAGE
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
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
    }
}

// MARK: - VUE PRINCIPALE DES STATISTIQUES
struct StatsView: View {
    @ObservedObject var data: GameData
    @ObservedObject var gameManager: GameManager
    
    @StateObject var authManager = AuthManager()
    
    @Environment(\.dismiss) var dismiss
    
    @State private var showingNameEditAlert = false
    @State private var tempUsername: String = ""
    
    @State private var debugClickCount = 0
    @State private var showingCodeAlert = false
    @State private var secretCodeInput = ""
    @State private var showingDebug = false
    
    // --- LOGIQUE NARRATIVE DYNAMIQUE ---
    var currentEvolutionStage: String {
        // On récupère tous les IDs d'actes débloqués
        let actes = data.cloudManager?.actesInfo ?? [:]
        let unlockedActes = actes.keys.filter { data.isActeUnlocked($0) }
        if let highestActe = unlockedActes.max(), let info = actes[highestActe] {
            return info.title
        }
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
                        
                        // --- SECTION 1 : STADE D'ÉVOLUTION ---
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
                                    .multilineTextAlignment(.center)
                                
                                // --- BARRE DE PROGRESSION ---
                                VStack(spacing: 8) {
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(Color.white.opacity(0.1))
                                                .frame(height: 10)
                                            
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(AppStyle.accentColor)
                                                // Utilisation directe de la valeur calculée
                                                .frame(width: geo.size.width * CGFloat(data.currentActeProgress), height: 10)
                                        }
                                    }
                                    .frame(height: 10)
                                    
                                    HStack {
                                        Text("Progression vers l'âge suivant")
                                        Spacer()
                                        // Affichage du pourcentage (lecture seule)
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
                        VStack(spacing: 15) {
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
                                    Image(systemName: "pencil.circle.fill").font(.title2).foregroundColor(.orange)
                                }
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            if let user = authManager.user {
                                HStack {
                                    Image(systemName: "cloud.fill").foregroundColor(AppStyle.positiveColor)
                                    VStack(alignment: .leading) {
                                        Text("Compte Invité Actif").font(.footnote).foregroundColor(.white)
                                        Text("ID : \(user.uid.prefix(10))...").font(.caption2).foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Text("Prêt pour Escouade ✅").font(.caption2).foregroundColor(AppStyle.positiveColor)
                                }
                            } else {
                                Button("Se connecter au Cloud") {
                                    authManager.signInAnonymously()
                                }
                                .foregroundColor(AppStyle.accentColor)
                            }
                        }
                        
                        // --- SECTION 3 : ÉCONOMIE ---
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
                        
                        // Footer narratif dynamique
                        let actes = data.cloudManager?.actesInfo ?? [:]
                        if let nextActe = actes.keys.filter({ !data.isActeUnlocked($0) }).min(),
                           let info = actes[nextActe] {
                            Text("Prochaine étape : \(info.title)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 10)
                        }
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
