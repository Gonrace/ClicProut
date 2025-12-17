import SwiftUI
import UIKit

// --- 1. STRUCTURES D'AIDE ---
struct FallingPoop: Identifiable {
    let id = UUID()
    let emoji: String = "💩"
    let x: CGFloat
    var y: CGFloat = 0
    let size: CGFloat
    let rotation: Angle
    let duration: Double
}

struct ContentView: View {
    
    // --- SOURCES DE VÉRITÉ ---
    @StateObject var data = GameData()
    @StateObject var audio = AudioEngine()
    @StateObject var gameManager = GameManager()
    
    // --- ÉTATS LOCAUX ---
    @State private var timer: Timer?
    @State private var fallingPoopTimer: Timer?
    
    // États pour l'ouverture des menus (Sheets)
    @State private var showingStats = false      // 1. Stats
    @State private var showingLeaderboard = false // 2. Classement
    @State private var showingCombat = false      // 3. Combat/Attaque
    @State private var showingInventory = false   // 4. Inventaire
    @State private var showingShop = false        // 5. Boutique
    @State private var showingDebug = false
    
    @State private var scale: CGFloat = 1.0
    @State private var autoScale: CGFloat = 1.0
    @State private var petAccumulator: Double = 0.0
    @State private var fallingPoops: [FallingPoop] = []
    
    let customBackground = Color(red: 0.1, green: 0.15, blue: 0.2)
    
    var body: some View {
        ZStack {
            // FOND
            customBackground.edgesIgnoringSafeArea(.all)
            
            // CALQUE DES PARTICULES (Pluie de caca)
            ForEach(fallingPoops) { poop in
                Text(poop.emoji)
                    .font(.system(size: poop.size))
                    .rotationEffect(poop.rotation)
                    .position(x: poop.x, y: poop.y)
                    .opacity(poop.y < 0 ? 0 : 1)
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
                    
                    // ALERTE D'ATTAQUE : Maintenant un bouton qui ouvre le menu Combat
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
                
                // --- BOUTON CENTRAL (LE CACA) ---
                Text("💩")
                    .font(.system(size: 110))
                    .shadow(color: .yellow.opacity(0.8), radius: 30)
                    .scaleEffect(data.calculatedPoopScale)
                    .scaleEffect(scale)
                    .scaleEffect(autoScale)
                    .onTapGesture { self.clickAction() }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in self.animateClick(isPressed: true) }
                            .onEnded { _ in self.animateClick(isPressed: false) }
                    )
                
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
                
                // --- BARRE DE NAVIGATION (ORDRE : Stats, Classement, Combat, Inventaire, Boutique) ---
                HStack(spacing: 0) {
                    // 1. Stats
                    NavButton(icon: "chart.bar.fill", action: { showingStats = true }, color: .purple)
                    
                    // 2. Classement
                    NavButton(icon: "trophy.fill", action: { showingLeaderboard = true }, color: .orange)
                    
                    // 3. COMBAT (CENTRAL - ÉCLAIR)
                    // On n'affiche le bouton de combat QUE si l'acte 2 est débloqué
                    if data.isActeUnlocked(2) {
                        Button(action: { showingCombat = true }) {
                            ZStack {
                                Circle()
                                    .fill(data.isUnderAttack ? Color.red : Color.gray.opacity(0.5))
                                    .frame(width: 55, height: 55)
                                    .shadow(color: data.isUnderAttack ? .red.opacity(0.6) : .black.opacity(0.3), radius: 8)
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                            .offset(y: -15)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        // Si l'acte 2 n'est pas débloqué, on met un espace vide ou un cadenas
                        VStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray.opacity(0.5))
                                .font(.caption)
                            Text("Acte 2").font(.system(size: 8)).foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .offset(y: -5)
                    }
                    // 4. Inventaire
                    NavButton(icon: "person.text.rectangle", action: { showingInventory = true }, color: .teal)
                    
                    // 5. Boutique
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
        }
        .onAppear {
            self.startAutoFartTimer()
            self.startFallingPoopTimer()
            self.gameManager.startObservingIncomingAttacks(data: data)
        }
        .onDisappear {
            self.timer?.invalidate()
            self.fallingPoopTimer?.invalidate()
        }
        // FENÊTRES (SHEETS)
        .sheet(isPresented: $showingStats) { StatsView(data: data, gameManager: gameManager).interactiveDismissDisabled(true) }
        .sheet(isPresented: $showingLeaderboard) { LeaderboardView(gameManager: gameManager, data: data).interactiveDismissDisabled(true) }
        .sheet(isPresented: $showingCombat) { CombatView(data: data).interactiveDismissDisabled(true) }
        .sheet(isPresented: $showingInventory) { InventoryView(data: data).interactiveDismissDisabled(true) }
        .sheet(isPresented: $showingShop) { ShopView(data: data).interactiveDismissDisabled(true) }
        .sheet(isPresented: $showingDebug) { DebugView(data: data).interactiveDismissDisabled(true) }
    }
    
    // --- LOGIQUE ENGINE ---
    func clickAction() {
        let produced = data.clickPower
        data.totalFartCount += produced
        data.lifetimeFarts += produced
        gameManager.saveLifetimeScore(lifetimeScore: data.lifetimeFarts)
        audio.triggerFart(isAuto: false)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func animateClick(isPressed: Bool) {
        withAnimation(.spring(response: 0.1, dampingFraction: 0.4)) {
            self.scale = isPressed ? 0.8 : 1.0
        }
    }
    
    func startAutoFartTimer() {
        self.timer?.invalidate()
        let tick = 0.05
        self.timer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { _ in
            let pps = data.petsPerSecond
            if pps <= 0 { return }
            self.petAccumulator += pps * tick
            if self.petAccumulator >= 1.0 {
                let new = Int(self.petAccumulator)
                data.totalFartCount += new
                data.lifetimeFarts += new
                self.petAccumulator -= Double(new)
                self.triggerPoopRainOnAutoFart(producedAmount: new)
            }
        }
    }
    
    func triggerPoopRainOnAutoFart(producedAmount: Int) {
        let num = min(max(producedAmount / 50, 1), 15)
        self.generatePoopRain(count: num)
    }
    
    func generatePoopRain(count: Int) {
        let screen = UIScreen.main.bounds
        for _ in 0..<count {
            let p = FallingPoop(
                x: .random(in: 0...screen.width),
                y: .random(in: -screen.height/2...0),
                size: .random(in: 15...35),
                rotation: .degrees(.random(in: -180...180)),
                duration: .random(in: 5...10)
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...0.5)) {
                self.fallingPoops.append(p)
            }
        }
    }
    
    func startFallingPoopTimer() {
        self.fallingPoopTimer?.invalidate()
        self.fallingPoopTimer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { _ in
            for i in self.fallingPoops.indices {
                self.fallingPoops[i].y += (50 / self.fallingPoops[i].duration) * (1/30) * 100
            }
            self.fallingPoops.removeAll { $0.y > UIScreen.main.bounds.height * 1.5 }
        }
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
