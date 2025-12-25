import SwiftUI
import FirebaseAuth

// MARK: - COMPOSANTS RÉUTILISABLES
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

// MARK: - VUE PRINCIPALE
struct StatsView: View {
    @ObservedObject var data: GameData
    @ObservedObject var gameManager: GameManager
    @ObservedObject var squadManager: SquadManager
    @ObservedObject var authManager: AuthManager
    
    @Environment(\.dismiss) var dismiss
    
    @State private var showingNameEditAlert = false
    @State private var tempUsername: String = ""
    @State private var showingSquadView = false
    
    // États pour le menu de triche / debug
    @State private var debugClickCount = 0
    @State private var showingCodeAlert = false
    @State private var secretCodeInput = ""
    @State private var showingDebug = false
    
    // MARK: - LOGIQUE DE DÉBLOCAGE ÉVOLUTIF
    
    /// Vérifie si un objet avec un certain effectID a été acheté
    func hasUnlockedEffect(_ effectID: String) -> Bool {
        guard let allItems = data.cloudManager?.allItems else { return false }
        // On récupère les noms de tous les items ayant cet effet
        let targetItemNames = allItems.filter { $0.effectID == effectID }.map { $0.name }
        // On vérifie si l'utilisateur possède au moins un de ces items
        return data.itemLevels.keys.contains { name in
            targetItemNames.contains(name) && data.itemLevels[name, default: 0] > 0
        }
    }

    var currentEvolutionStage: String {
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
                // 1. BARRE DE TITRE
                CustomTitleBar(title: "Profil & Stats 📊", onDismiss: { dismiss() })
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
                        
                        // --- SECTION A : PROFIL (Toujours visible) ---
                        VStack(alignment: .leading, spacing: 12) {
                            Text("IDENTITÉ").font(.caption).fontWeight(.bold).foregroundColor(.gray)
                            
                            VStack(spacing: 0) {
                                // Pseudo
                                HStack {
                                    Image(systemName: "person.circle.fill").foregroundColor(AppStyle.accentColor)
                                    Text(gameManager.username).fontWeight(.bold).foregroundColor(.white)
                                    Spacer()
                                    Button {
                                        tempUsername = gameManager.username
                                        showingNameEditAlert = true
                                    } label: {
                                        Image(systemName: "pencil").foregroundColor(.orange)
                                    }
                                }.padding()

                                // ID Cloud (si connecté)
                                if let user = authManager.user {
                                    Divider().background(Color.white.opacity(0.1))
                                    HStack {
                                        Image(systemName: "icloud.fill").foregroundColor(.blue).font(.caption)
                                        Text("ID Cloud: \(user.uid.prefix(12))...").font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
                                        Spacer()
                                    }.padding(.horizontal).padding(.vertical, 8)
                                }
                            }
                            .background(AppStyle.listRowBackground)
                            .cornerRadius(12)
                        }

                        // --- SECTION B : ÉVOLUTION (Débloquée par 'unlock_histoire') ---
                        if hasUnlockedEffect("unlock_histoire") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("STADE D'ÉVOLUTION").font(.caption).fontWeight(.bold).foregroundColor(.gray)
                                
                                VStack(spacing: 15) {
                                    Text(currentEvolutionStage)
                                        .font(.headline).fontWeight(.black).foregroundColor(AppStyle.accentColor)
                                    
                                    // Barre de progression
                                    VStack(spacing: 6) {
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1))
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(AppStyle.accentColor)
                                                    .frame(width: geo.size.width * CGFloat(data.currentActeProgress))
                                            }
                                        }.frame(height: 8)
                                        
                                        HStack {
                                            Text("Progression de l'Acte").font(.caption2).foregroundColor(.gray)
                                            Spacer()
                                            Text("\(Int(data.currentActeProgress * 100))%").font(.caption2).bold().foregroundColor(.gray)
                                        }
                                    }
                                }
                                .padding()
                                .background(AppStyle.listRowBackground)
                                .cornerRadius(12)
                            }
                        }

                        // --- SECTION C : ESCOUADE (Débloquée par 'unlock_hub') ---
                        if hasUnlockedEffect("unlock_hub") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("SOCIAL").font(.caption).fontWeight(.bold).foregroundColor(.gray)
                                
                                Button(action: { showingSquadView = true }) {
                                    HStack {
                                        Image(systemName: "person.3.fill")
                                            .font(.title3)
                                            .foregroundColor(.black)
                                            .frame(width: 40, height: 40)
                                            .background(AppStyle.accentColor)
                                            .cornerRadius(8)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            if let squad = squadManager.currentSquad {
                                                Text(squad.name).font(.subheadline).bold()
                                                Text("Gérer mon escouade").font(.caption2).opacity(0.8)
                                            } else {
                                                Text("Rejoindre une Escouade").font(.subheadline).bold()
                                                Text("Trouvez des alliés pour l'Acte 4").font(.caption2).opacity(0.8)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right").font(.caption).opacity(0.5)
                                    }
                                    .padding(12)
                                    .background(AppStyle.listRowBackground)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                        }

                        // --- SECTION D : CHIFFRES (Toujours visible) ---
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ÉCONOMIE & PERF").font(.caption).fontWeight(.bold).foregroundColor(.gray)
                            VStack(spacing: 0) {
                                StatRow(title: "Pets actuels", value: "\(data.totalFartCount) 💩")
                                Divider().background(Color.white.opacity(0.1))
                                StatRow(title: "PQ d'Or", value: "\(data.goldenToiletPaper) 👑")
                                Divider().background(Color.white.opacity(0.1))
                                StatRow(title: "Total à vie", value: "\(data.lifetimeFarts) 🏆")
                                Divider().background(Color.white.opacity(0.1))
                                StatRow(title: "Auto-Production", value: String(format: "%.2f PPS", data.petsPerSecond))
                                Divider().background(Color.white.opacity(0.1))
                                StatRow(title: "Puissance de Clic", value: "\(data.clickPower) PPC")
                            }
                            .background(AppStyle.listRowBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding(AppStyle.defaultPadding)
                }
            }
        }
        // --- NAVIGATION & ALERTES ---
        .sheet(isPresented: $showingSquadView) {
            SquadView(data: data, squadManager: squadManager, authManager: authManager, gameManager: gameManager)
        }
        .sheet(isPresented: $showingDebug) {
            DebugView(data: data)
        }
        .alert("Modifier votre Nom", isPresented: $showingNameEditAlert) {
            TextField("Nouveau nom", text: $tempUsername)
            Button("Valider") {
                let trimmed = tempUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { gameManager.saveNewUsername(trimmed, lifetimeScore: data.lifetimeFarts) }
            }
            Button("Annuler", role: .cancel) { }
        }
        .alert("Accès Développeur", isPresented: $showingCodeAlert) {
            SecureField("Code secret", text: $secretCodeInput)
            Button("Valider") {
                if secretCodeInput == "PROUT2025" { showingDebug = true }
                secretCodeInput = ""
            }
            Button("Annuler", role: .cancel) { secretCodeInput = "" }
        }
    }
}
