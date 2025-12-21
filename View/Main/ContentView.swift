import SwiftUI
import UIKit

struct ContentView: View {
    
    // --- SOURCES DE VÉRITÉ ---
    @StateObject var data: GameData
    @StateObject var audio = AudioEngine()
    @StateObject var gameManager = GameManager()
    @StateObject var poopManager: PoopEntityManager
    @StateObject var socialManager = SocialManager()
    @StateObject var timerManager: GameTimerManager
    
    // --- INITIALISATION DES MANAGERS RELIÉS ---
        init() {
            // 1. On crée les instances de base
            let d = GameData()
            let p = PoopEntityManager()
            
            // 2. On les injecte dans le StateObject via leur "wrappedValue"
            _data = StateObject(wrappedValue: d)
            _poopManager = StateObject(wrappedValue: p)
            
            // 3. On crée le TimerManager en lui passant les deux autres
            _timerManager = StateObject(wrappedValue: GameTimerManager(data: d, poopManager: p))
        }
    
    // --- ETATS UI ---
    @State private var isPoopRainEnabled: Bool = true
    @State private var showingStats = false
    @State private var showingLeaderboard = false
    @State private var showingCombat = false
    @State private var showingInventory = false
    @State private var showingShop = false
    @State private var showingDebug = false
    
    let customBackground = Color(red: 0.1, green: 0.15, blue: 0.2)
    
    var body: some View {
        ZStack {
            // FOND
            customBackground.edgesIgnoringSafeArea(.all)
            
            // CALQUE DES PARTICULES (Pluie de caca)
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
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.orange.opacity(0.8))
                        .cornerRadius(8)
                }
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.3)
                .transition(.scale)
            }
            
            VStack(spacing: 0) {
                // --- EN-TÊTE : SCORE & ALERTE ---
                VStack(spacing: 5) {
                    Text("\(data.totalFartCount)")
                        .font(.system(size: 60, weight: .heavy, design: .rounded))
                        .foregroundColor(.yellow)
                        .animation(.spring(), value: data.totalFartCount)
                    
                    Text("PPS: \(String(format: "%.2f", data.petsPerSecond)) | PPC: \(data.clickPower)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    Text("PQ d'Or: \(data.goldenToiletPaper) 👑")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    
                    if data.isUnderAttack && data.isActeUnlocked(2) {
                        Button(action: { showingCombat = true }) {
                            HStack(spacing: 10) {
                                Image(systemName: "bolt.shield.fill")
                                    .font(.title3)
                                
                                VStack(alignment: .leading) {
                                    Text("ATTAQUE DE \(data.lastAttackerName.uppercased()) !")
                                        .font(.caption).fontWeight(.black)
                                    Text("Touché par : \(data.lastAttackWeapon)")
                                        .font(.system(size: 10))
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(Color.red.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.6), lineWidth: 1))
                        }
                        .padding(.top, 10)
                        .shadow(radius: 5)
                    }
                }
                .padding(.top, 50)
                
                Spacer()
                
                // --- BOUTON CENTRAL ---
                MainButtonView(data: data) {
                    self.clickAction()
                }
                
                Spacer()
                
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
                .frame(height: 50)
                .padding(.bottom, 10)
                
                // --- BARRE DE NAVIGATION ---
                HStack(spacing: 0) {
                    NavButton(icon: "chart.bar.fill", action: { showingStats = true }, color: .purple)
                    NavButton(icon: "trophy.fill", action: { showingLeaderboard = true }, color: .orange)
                    
                    if data.isActeUnlocked(2) {
                        Button(action: { showingCombat = true }) {
                            ZStack {
                                Circle()
                                    .fill(data.isUnderAttack ? Color.red : Color.gray.opacity(0.5))
                                    .frame(width: 55, height: 55)
                                    .shadow(color: data.isUnderAttack ? .red.opacity(0.6) : .black.opacity(0.3), radius: 8)
                                Image(systemName: "toilet.fill")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                            .offset(y: -15)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray.opacity(0.5))
                                .font(.caption)
                            Text("Acte 2").font(.system(size: 8)).foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .offset(y: -5)
                    }
                    
                    NavButton(icon: "person.text.rectangle", action: { showingInventory = true }, color: .teal)
                    NavButton(icon: "bag.fill", action: { showingShop = true }, color: .blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.4))
                .cornerRadius(20)
                .padding(.horizontal, 15)
                .padding(.bottom, 20)
            }
            
            NotificationOverlay(data: data)
        }
        .onAppear {
            // Le TimerManager s'occupe maintenant de l'auto-fart et de la pluie auto
            timerManager.startAutoFartTimer()
                    
            // Le PoopManager s'occupe de faire descendre les cacas
            poopManager.startFallingPoopTimer()
                    
            socialManager.startObservingInteractions(gameData: data)
            gameManager.startObservingLeaderboard()
        }
        .onDisappear {
                // On arrête proprement le moteur de temps
            timerManager.stopTimer()
        }
        .sheet(isPresented: $showingStats) { StatsView(data: data, gameManager: gameManager).interactiveDismissDisabled(true) }
        .sheet(isPresented: $showingLeaderboard) { LeaderboardView(gameManager: gameManager, data: data, socialManager: socialManager) .interactiveDismissDisabled(true)}
        .sheet(isPresented: $showingCombat) {InteractionsView(data: data, gameManager: gameManager, socialManager: socialManager).interactiveDismissDisabled(true)}
        .sheet(isPresented: $showingInventory) { InventoryView(data: data).interactiveDismissDisabled(true) }
        .sheet(isPresented: $showingShop) { ShopView(data: data).interactiveDismissDisabled(true) }
        .sheet(isPresented: $showingDebug) { DebugView(data: data).interactiveDismissDisabled(true) }
    }
    
    // --- LOGIQUE ENGINE ---
    func clickAction() {
        data.processProutClick()
        gameManager.saveLifetimeScore(lifetimeScore: data.lifetimeFarts)
        audio.triggerFart(isAuto: false)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        data.checkNotifications()
        // Ajout : Pluie au clic manuel si tu veux
        poopManager.generatePoopRain(count: 1)
    }
}

// --- STRUCTURE NAV ---
struct NavButton: View {
    let icon: String
    let action: () -> Void
    let color: Color
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .frame(maxWidth: .infinity)
                .foregroundColor(color)
        }
    }
}
