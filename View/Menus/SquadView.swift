import SwiftUI

struct SquadView: View {
    @ObservedObject var data: GameData
    @ObservedObject var squadManager: SquadManager
    @ObservedObject var authManager: AuthManager
    @ObservedObject var gameManager: GameManager
    
    @Environment(\.dismiss) var dismiss
    @State private var squadNameInput = ""
    @State private var joinIDInput = ""
    @State private var showingCreateAlert = false
    @State private var showingJoinAlert = false

    // Tri des membres pour un affichage stable
    private var sortedMembers: [(id: String, name: String)] {
        guard let members = squadManager.currentSquad?.members else { return [] }
        return members.map { (id: $0.key, name: $0.value) }.sorted { $0.name < $1.name }
    }

    var body: some View {
        ZStack {
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                CustomTitleBar(title: "Mon Escouade 🤝", onDismiss: { dismiss() })
                
                if let squad = squadManager.currentSquad {
                    // --- VUE : UTILISATEUR EN ESCOUADE ---
                    ScrollView {
                        VStack(spacing: 20) {
                            squadHeader(squad: squad)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("MEMBRES (\(squad.members.count))")
                                    .font(.caption).bold().foregroundColor(.gray)
                                
                                ForEach(sortedMembers, id: \.id) { member in
                                    memberRow(memberID: member.id, name: member.name, leaderID: squad.leaderID)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Bouton Quitter (Maintenant fonctionnel)
                            Button(action: {
                                if let user = authManager.user {
                                    squadManager.leaveSquad(user: user)
                                }
                            }) {
                                Text("QUITTER L'ESCOUADE")
                                    .font(.caption).bold()
                                    .foregroundColor(.red.opacity(0.7))
                                    .padding(.vertical, 20)
                            }
                        }
                        .padding(.vertical)
                    }
                } else {
                    // --- VUE : RECHERCHE D'ESCOUADE ---
                    emptySquadView
                }
            }
        }
        .alert("Nom de l'escouade", isPresented: $showingCreateAlert) {
            TextField("Ex: Les Fous du Prout", text: $squadNameInput)
            Button("Créer") {
                if let user = authManager.user {
                    squadManager.createSquad(name: squadNameInput, user: user, username: gameManager.username)
                }
            }
            Button("Annuler", role: .cancel) {}
        }
        .alert("Rejoindre une escouade", isPresented: $showingJoinAlert) {
            TextField("Coller l'ID ici", text: $joinIDInput)
            Button("Rejoindre") {
                if let user = authManager.user {
                    squadManager.joinSquad(squadID: joinIDInput, user: user, username: gameManager.username)
                }
            }
            Button("Annuler", role: .cancel) {}
        }
    }

    // --- COMPOSANTS ---

    private func squadHeader(squad: Squad) -> some View {
        VStack(spacing: 8) {
            Text(squad.name).font(.system(size: 28, weight: .black, design: .rounded)).foregroundColor(AppStyle.accentColor)
            HStack {
                Text("ID : \(squad.id)").font(.system(.caption2, design: .monospaced)).foregroundColor(.gray)
                Button(action: { UIPasteboard.general.string = squad.id }) {
                    Image(systemName: "doc.on.doc").font(.caption2)
                }.foregroundColor(AppStyle.accentColor)
            }
        }
        .padding().frame(maxWidth: .infinity).background(AppStyle.listRowBackground).cornerRadius(15).padding(.horizontal)
    }

    private func memberRow(memberID: String, name: String, leaderID: String) -> some View {
        let isOnline = squadManager.isUserOnline(userID: memberID)
        
        return HStack {
            Circle()
                .fill(isOnline ? Color.green : Color.red)
                .frame(width: 8, height: 8)
                .shadow(color: isOnline ? .green.opacity(0.5) : .clear, radius: 3)
            
            Text(name).foregroundColor(.white).fontWeight(.medium)
            Spacer()
            if memberID == leaderID {
                Text("CHEF").font(.system(size: 8, weight: .black)).padding(4).background(AppStyle.accentColor).foregroundColor(.black).cornerRadius(4)
            }
        }
        .padding().background(Color.white.opacity(0.05)).cornerRadius(10)
    }

    private var emptySquadView: some View {
        VStack(spacing: 30) {
            Spacer()
            ZStack {
                Circle().fill(AppStyle.accentColor.opacity(0.1)).frame(width: 150, height: 150)
                Image(systemName: "person.3.fill").font(.system(size: 60)).foregroundColor(AppStyle.accentColor)
            }
            Text("À plusieurs, on proute plus fort !").font(.title2).bold().foregroundColor(.white)
            VStack(spacing: 15) {
                Button("CRÉER MON CLAN") { showingCreateAlert = true }.frame(maxWidth: .infinity).padding().background(AppStyle.accentColor).foregroundColor(.black).cornerRadius(12)
                Button("REJOINDRE AVEC UN ID") { showingJoinAlert = true }.frame(maxWidth: .infinity).padding().background(Color.white.opacity(0.1)).foregroundColor(.white).cornerRadius(12)
            }
            .padding(.horizontal, 30)
            Spacer()
        }
    }
}
