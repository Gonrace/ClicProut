import SwiftUI

// NOTE: Les classes GameData, AudioEngine, et GameManager doivent exister.

struct ContentView: View {
    
    // --- SOURCES DE VÉRITÉ ---
    @StateObject var data = GameData()
    @StateObject var audio = AudioEngine()
    @StateObject var gameManager = GameManager() // Gestionnaire Firebase
    
    // --- ÉTATS LOCAUX (Vues & Animation) ---
    @State private var timer: Timer?
    
    // Gestion des fenêtres
    @State private var showingShop = false      // Page Magasin
    @State private var showingStats = false     // Page Statistique
    @State private var showingLeaderboard = false // Page Classement
    
    // Animations visuelles
    @State private var scale: CGFloat = 1.0     // Écrasement (Clic Manuel)
    @State private var autoScale: CGFloat = 1.0 // Petit Rebond (Auto-Pet)
    
    // Logique mathématique (Accumulateur pour les pets à virgule)
    @State private var petAccumulator: Double = 0.0
    
    // Couleur de fond (Bleu nuit apaisant)
    let customBackground = Color(red: 0.1, green: 0.15, blue: 0.2)
    
    var body: some View {
        ZStack {
            // 1. Fond d'écran
            customBackground.edgesIgnoringSafeArea(.all)
            
            VStack {
                
                // 2. EN-TÊTE : SCORE & PPS
                VStack(spacing: 5) {
                    Text("\(data.totalFartCount)")
                        .font(.system(size: 60, weight: .heavy, design: .rounded))
                        .foregroundColor(.yellow)
                        .animation(.spring(), value: data.totalFartCount)
                                    
                    Text("Pets Par Seconde: \(String(format: "%.2f", data.petsPerSecond))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .padding(.top, 5)

                    // Puissance de Clic
                    Text("Pets Par Clic: \(data.clickPower)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green.opacity(0.7))
                }
                .padding(.top, 50)
                
                Spacer()
                
                // 3. LE BOUTON CENTRAL (CACA)
                Text("💩")
                    .font(.system(size: 110))
                    .shadow(color: .yellow.opacity(0.8), radius: 30)
                    
                    .scaleEffect(data.calculatedPoopScale)
                    .scaleEffect(scale)     // Écrasement manuel
                    .scaleEffect(autoScale) // Rebond auto
                    
                    .onTapGesture {
                        self.clickAction()
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in self.animateClick(isPressed: true) }
                            .onEnded { _ in self.animateClick(isPressed: false) }
                    )
                
                Spacer()
                
                // 4. INVENTAIRE (Objets possédés affichés en bas)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(data.ownedItemsDisplay, id: \.self) { item in
                            Text(item)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 10)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 50)
                .padding(.bottom, 20)

                
                // 5. BARRE DE NAVIGATION (Icônes uniquement)
                HStack(spacing: 0) {
                    // BOUTON STATS
                    NavButton(icon: "chart.bar.fill", action: { showingStats = true }, color: .purple)
                    
                    // BOUTON CLASSEMENT
                    NavButton(icon: "trophy.fill", action: { showingLeaderboard = true }, color: .orange)
                    
                    // BOUTON PROUTIQUE
                    NavButton(icon: "bag.fill", action: { showingShop = true }, color: .blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.4))
                .cornerRadius(15)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        // --- LOGIQUE INVISIBLE (LIFECYCLE) ---
        
        .onAppear { self.startAutoFartTimer() }
        .onChange(of: data.petsPerSecond) { _ in self.startAutoFartTimer() }
        .onDisappear { self.timer?.invalidate(); self.timer = nil }
        
        // OUVERTURE DES FENÊTRES (SHEETS)
        .sheet(isPresented: $showingShop) {
            ShopView(data: data)
                .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $showingStats) {
            StatsView(data: data, gameManager: gameManager)
                .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $showingLeaderboard) {
            LeaderboardView(gameManager: gameManager)
                .interactiveDismissDisabled(true)
        }
    }
    
    // --- FONCTIONS ET LOGIQUE ---
    
    func clickAction() {
        data.totalFartCount += data.clickPower
        gameManager.saveScore(score: data.totalFartCount)
        audio.triggerFart(isAuto: false)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func animateClick(isPressed: Bool) {
        withAnimation(.spring(response: 0.1, dampingFraction: 0.4)) {
            self.scale = isPressed ? 0.8 : 1.0
        }
    }
    
    func triggerAutoPulse() {
        withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
            self.autoScale = 1.05
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
                self.autoScale = 1.0
            }
        }
    }
    
    func startAutoFartTimer() {
        self.timer?.invalidate()
        self.timer = nil
        
        let pps = data.petsPerSecond
        if pps == 0 { return }
        
        let tickRate = 0.05
        
        self.timer = Timer.scheduledTimer(withTimeInterval: tickRate, repeats: true) { _ in
            
            self.petAccumulator += pps * tickRate
            
            if self.petAccumulator >= 1.0 {
                
                let newPets = Int(self.petAccumulator)
                
                data.totalFartCount += newPets
                gameManager.saveScore(score: data.totalFartCount)
                self.petAccumulator -= Double(newPets)
                
                if pps < 5.0 {
                    audio.triggerFart(isAuto: true)
                    self.triggerAutoPulse()
                }
            }
        }
    }
}

// Composant pour les boutons de navigation (Icône seule)
struct NavButton: View {
    let icon: String
    let action: () -> Void
    let color: Color
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .foregroundColor(color)
        }
    }
}

// Prévisualisation pour Xcode
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
