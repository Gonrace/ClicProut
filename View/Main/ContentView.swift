import SwiftUI
import UIKit
import FirebaseAuth

struct ContentView: View {
    
    // --- SOURCES DE VÉRITÉ ---
    @StateObject var cloudManager: CloudConfigManager
    @StateObject var data: GameData
    @StateObject var audio: AudioEngine
    @StateObject var gameManager: GameManager
    @StateObject var poopManager: PoopEntityManager
    @StateObject var socialManager: SocialManager
    @StateObject var timerManager: GameTimerManager
    @StateObject var authManager: AuthManager
    @StateObject var squadManager: SquadManager
    
    // --- INITIALISATION DES MANAGERS RELIÉS ---
    init() {
        let cloud = CloudConfigManager()
        let d = GameData()
        let p = PoopEntityManager()
        let auth = AuthManager()
        let squad = SquadManager()
            
        d.cloudManager = cloud
            
        let tm = GameTimerManager(data: d, poopManager: p)
        tm.squadManager = squad
        tm.authManager = auth
            
        _cloudManager = StateObject(wrappedValue: cloud)
        _data = StateObject(wrappedValue: d)
        _poopManager = StateObject(wrappedValue: p)
        _authManager = StateObject(wrappedValue: auth)
        _squadManager = StateObject(wrappedValue: squad)
        _timerManager = StateObject(wrappedValue: tm)
            
        _audio = StateObject(wrappedValue: AudioEngine())
        _gameManager = StateObject(wrappedValue: GameManager())
        _socialManager = StateObject(wrappedValue: SocialManager())
    }
        
    // --- ETATS UI ---
    @State private var isPoopRainEnabled: Bool = true
    @State private var showingStats = false
    @State private var showingLeaderboard = false
    @State private var showingCombat = false
    @State private var showingInventory = false
    @State private var showingShop = false
    @State private var showingDebug = false
    @State private var showingSquadView = false
    
    let customBackground = Color(red: 0.1, green: 0.15, blue: 0.2)
    
    var body: some View {
        ZStack {
            // FOND
            customBackground.edgesIgnoringSafeArea(.all)
            
            // CALQUE DES PARTICULES
            PoopRainView(fallingPoops: poopManager.fallingPoops, isEnabled: isPoopRainEnabled)
            
            // VERIFICATION VOLUME UTILISATEUR
            if data.isMuted {
                VStack(spacing: 10) {
                    Image(systemName: "speaker.slash.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                        .shadow(radius: 10)
                    VolumeObserver().frame(width: 0, height: 0)
                    
                    Text("C'est moins drôle sans le son...")
                        .font(.caption).fontWeight(.bold).foregroundColor(.white)
                        .padding(8).background(Color.orange.opacity(0.8)).cornerRadius(8)
                }
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.3)
                .transition(.scale)
            }
            
            VStack(spacing: 0) {
                // --- EN-TÊTE : SCORE ---
                VStack(spacing: 5) {
                    Text("\(data.totalFartCount)")
                        .font(.system(size: 60, weight: .heavy, design: .rounded))
                        .foregroundColor(.yellow)
                        .animation(.spring(), value: data.totalFartCount)
                    
                    Text("PPS: \(String(format: "%.2f", data.petsPerSecond)) | PPC: \(data.clickPower)")
                        .font(.caption).fontWeight(.bold).foregroundColor(.gray)
                    
                    Text("PQ d'Or: \(data.goldenToiletPaper) 👑")
                        .font(.caption).fontWeight(.bold).foregroundColor(.yellow)
                    
                    if data.isUnderAttack && data.isActeUnlocked(2) {
                        Button(action: { showingCombat = true }) {
                            HStack(spacing: 10) {
                                Image(systemName: "bolt.shield.fill").font(.title3)
                                VStack(alignment: .leading) {
                                    Text("ATTAQUE DE \(data.lastAttackerName.uppercased()) !").font(.caption).fontWeight(.black)
                                    Text("Touché par : \(data.lastAttackWeapon)").font(.system(size: 10))
                                }
                            }
                            .padding(.vertical, 8).padding(.horizontal, 15)
                            .background(Color.red.opacity(0.9)).foregroundColor(.white).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.6), lineWidth: 1))
                        }
                        .padding(.top, 10).shadow(radius: 5)
                    }
                }
                .padding(.top, 50)
                
                Spacer() // Pousse le bouton vers le centre
                
                // --- BOUTON CENTRAL ---
                MainButtonView(data: data) { self.clickAction() }
                
                Spacer() // Pousse la barre vers le bas
                
                // --- BANNIÈRE BONUS X2 (POSITIONNÉE ICI : JUSTE AU DESSUS DE LA BARRE) ---
                if squadManager.isFullSquadOnline() {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                        Text("BONUS ESCOUADE x2 ACTIVÉ !")
                            .fontWeight(.black)
                        Image(systemName: "flame.fill")
                    }
                    .font(.system(size: 10, design: .rounded))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .shadow(color: .orange.opacity(0.4), radius: 6)
                    .padding(.bottom, 12) // Espace avant l'inventaire
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                    .zIndex(1)
                }

                // --- INVENTAIRE RAPIDE ---
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(data.ownedItemsDisplay, id: \.self) { item in
                            Text(item)
                                .font(.headline).foregroundColor(.white)
                                .padding(.vertical, 5).padding(.horizontal, 10)
                                .background(Color.white.opacity(0.1)).cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 50).padding(.bottom, 10)
                
                // --- BARRE DE NAVIGATION ---
                HStack(spacing: 0) {
                    NavButton(icon: "chart.bar.fill", action: { showingStats = true }, color: .purple)
                    NavButton(icon: "trophy.fill", action: { showingLeaderboard = true }, color: .orange)
                    
                    if data.isActeUnlocked(2) {
                        Button(action: { showingCombat = true }) {
                            ZStack {
                                Circle().fill(data.isUnderAttack ? Color.red : Color.gray.opacity(0.5)).frame(width: 55, height: 55)
                                Image(systemName: "toilet.fill").foregroundColor(.white).font(.title2)
                            }
                            .offset(y: -15)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack {
                            Image(systemName: "lock.fill").foregroundColor(.gray.opacity(0.5)).font(.caption)
                            Text("Acte 2").font(.system(size: 8)).foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity).offset(y: -5)
                    }
                    
                    NavButton(icon: "person.text.rectangle", action: { showingInventory = true }, color: .teal)
                    NavButton(icon: "bag.fill", action: { showingShop = true }, color: .blue)
                }
                .frame(maxWidth: .infinity).padding(.horizontal, 10).padding(.vertical, 8)
                .background(Color.black.opacity(0.4)).cornerRadius(20).padding(.horizontal, 15).padding(.bottom, 20)
            }
            
            NotificationOverlay(data: data)
        }
        .onAppear {
            cloudManager.startFirebaseSync {
                if let user = authManager.user {
                    squadManager.observeUserSquad(user: user)
                }
                data.checkNotifications()
            }
            
            timerManager.startAutoFartTimer()
            poopManager.startFallingPoopTimer()
            
            // Heartbeat haute fréquence (toutes les 10s) pour la bannière x2
            Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
                if let userID = authManager.user?.uid {
                    squadManager.updateMyActivity(userID: userID)
                }
            }
            
            socialManager.startObservingInteractions(gameData: data)
            gameManager.startObservingLeaderboard()
        }
        .onDisappear {
            timerManager.stopTimer()
        }
        .sheet(isPresented: $showingLeaderboard) { LeaderboardView(gameManager: gameManager, data: data, socialManager: socialManager).interactiveDismissDisabled(true) }
        .sheet(isPresented: $showingCombat) { InteractionsView(data: data, gameManager: gameManager, socialManager: socialManager).interactiveDismissDisabled(true) }
        .sheet(isPresented: $showingInventory) { InventoryView(data: data).interactiveDismissDisabled(true) }
        .sheet(isPresented: $showingShop) { ShopView(data: data).interactiveDismissDisabled(true) }
        .sheet(isPresented: $showingDebug) { DebugView(data: data).interactiveDismissDisabled(true) }
        .sheet(isPresented: $showingStats) { StatsView(data: data, gameManager: gameManager, squadManager: squadManager, authManager: authManager).interactiveDismissDisabled(true) }
        .alert("Bon retour !", isPresented: Binding(
            get: { data.lastOfflineGain > 0 },
            set: { _ in data.lastOfflineGain = 0 }
        )) {
            Button("Merci les gars ! 💨") { }
        } message: {
            Text("Tes alliés ont maintenu la production ! Tu as récolté \(data.lastOfflineGain) pets pendant ton absence.")
        }
    }
    
    func clickAction() {
        data.processProutClick()
        gameManager.saveLifetimeScore(lifetimeScore: data.lifetimeFarts)
        audio.triggerFart(isAuto: false)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        data.checkNotifications()
        poopManager.generatePoopRain(count: 1)
    }
}

struct NavButton: View {
    let icon: String
    let action: () -> Void
    let color: Color
    var body: some View {
        Button(action: action) {
            Image(systemName: icon).font(.title3).frame(maxWidth: .infinity).foregroundColor(color)
        }
    }
}
