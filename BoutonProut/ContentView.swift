import SwiftUI

// NOTE: Les classes GameData, AudioEngine, et GameManager doivent exister.

// --- STRUCTURE D'AIDE pour l'animation ---
struct FallingPoop: Identifiable {
    let id = UUID()
    let emoji: String = "💩"
    let x: CGFloat          // Position horizontale de départ
    var y: CGFloat = 0      // Position verticale (défilement)
    let size: CGFloat       // Taille de la merde
    let rotation: Angle     // Angle de rotation
    let duration: Double    // Vitesse de défilement
}

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
    @State private var showingInventory = false // Page mes Objets
    
    // Animations visuelles
    @State private var scale: CGFloat = 1.0      // Écrasement (Clic Manuel)
    @State private var autoScale: CGFloat = 1.0  // Petit Rebond (Auto-Pet)
    
    // Logique mathématique (Accumulateur pour les pets à virgule)
    @State private var petAccumulator: Double = 0.0
    
    // NOUVEAU : Tableau pour stocker les particules animées
    @State private var fallingPoops: [FallingPoop] = []
            
    // NOUVEAU : Timer pour l'animation de chute
    @State private var fallingPoopTimer: Timer?
    
    // Ajout de l'état pour la vue de débogage
    @State private var showingDebug = false // A ajouter
    
    // Couleur de fond (Bleu nuit apaisant)
    let customBackground = Color(red: 0.1, green: 0.15, blue: 0.2)
    
    var body: some View {
        ZStack {
            // 1. Fond d'écran
            customBackground.edgesIgnoringSafeArea(.all)
            
            // NOUVEAU : Calque des Particules de merde
            ForEach(fallingPoops) { poop in
                Text(poop.emoji)
                    .font(.system(size: poop.size))
                    .rotationEffect(poop.rotation)
                    // Positionnement absolu sur l'écran
                    .position(x: poop.x, y: poop.y)
                    .opacity(poop.y < 0 ? 0 : 1) // Cache au-dessus de l'écran
            }
            
            VStack {
                
                // 2. EN-TÊTE : SCORE & PPS & PPC & PQ D'OR
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
                        
                    // PQ D'OR (Ajouté pour la cohérence de l'affichage)
                    Text("PQ d'Or: \(data.goldenToiletPaper) 👑")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .padding(.top, 5)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // 3. LE BOUTON CENTRAL (CACA)
                Text("💩")
                    .font(.system(size: 110))
                    .shadow(color: .yellow.opacity(0.8), radius: 30)
                    
                    .scaleEffect(data.calculatedPoopScale)
                    .scaleEffect(scale)      // Écrasement manuel
                    .scaleEffect(autoScale)  // Rebond auto
                    
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
                    
                    // BOUTON OBJETS (INVENTAIRE)
                    NavButton(icon: "person.text.rectangle", action: { showingInventory = true }, color: .teal)
                    
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
        
        .onAppear {
            self.startAutoFartTimer()
            self.startFallingPoopTimer() // Démarrer le timer d'animation
        }
        
        .onChange(of: data.petsPerSecond) { self.startAutoFartTimer() }

        // NOUVEAU: Ajout de la logique de réinitialisation ici
        .onChange(of: data.totalFartCount) {
            // Si le score est ramené à zéro ET l'inventaire est vide (après un softReset)
            if data.totalFartCount == 0 && data.itemLevels.isEmpty {
                self.startAutoFartTimer() // Force le redémarrage (ou l'arrêt) du timer PPS
            }
        }
        
        // Ajout des accolades pour le onDisappear et utilise le bon timer
        .onDisappear {
            self.timer?.invalidate(); self.timer = nil
            self.fallingPoopTimer?.invalidate(); self.fallingPoopTimer = nil // Arrête le timer
        }
        
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
        .sheet(isPresented: $showingInventory) {
            InventoryView(data: data)
                .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $showingDebug) {
            // NOTE IMPORTANTE : Il faut passer la data pour que la réinitialisation fonctionne
            DebugView(data: data)
                .interactiveDismissDisabled(true)
        }
        // FIN DE body
    }
    // --- FONCTIONS ET LOGIQUE (PLACÉES CORRECTEMENT DANS LA STRUCTURE) ---

    func clickAction() {
        let producedPets = data.clickPower
        
        data.totalFartCount += producedPets
        data.lifetimeFarts += producedPets
        
        gameManager.saveLifetimeScore(lifetimeScore: data.lifetimeFarts)
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
                data.lifetimeFarts += newPets
                
                gameManager.saveLifetimeScore(lifetimeScore: data.lifetimeFarts)
                self.petAccumulator -= Double(newPets)
                
                // LOGIQUE DE PLUIE DE CACA
                self.triggerPoopRainOnAutoFart(producedAmount: newPets)
                
                if pps < 5.0 {
                    audio.triggerFart(isAuto: true)
                    self.triggerAutoPulse()
                }
            }
        }
    }
    
    func triggerPoopRainOnAutoFart(producedAmount: Int) {
        // CORRECTION : Le nombre de caca est proportionnel aux pets produits lors du tick.
            
        // Nous allons limiter la quantité maximale pour éviter de submerger l'écran ou le CPU.
        // Facteur de conversion : 1 caca pour 50 pets produits
        let conversionFactor = 50
            
        // Nombre de caca à générer (au moins 1 si la production est > 0)
        let maxPoopsToGenerate = 15 // Limitation stricte pour les performances
            
        var numPoops = producedAmount / conversionFactor
            
        // S'assurer qu'au moins 1 caca tombe si la production est positive mais faible
        if producedAmount > 0 && numPoops == 0 {
                numPoops = 1
        }
            
        // Appliquer la limitation maximale
        numPoops = min(numPoops, maxPoopsToGenerate)
            
        if numPoops > 0 {
            self.generatePoopRain(count: numPoops)
        }
    }
    
    
    // Crée un lot de particules qui vont tomber à l'écran.
    func generatePoopRain(count: Int) {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        for _ in 0..<count {
            let newPoop = FallingPoop(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: -screenHeight / 2 ... 0), // Commence au-dessus
                size: CGFloat.random(in: 15...35),
                rotation: .degrees(Double.random(in: -180...180)),
                duration: Double.random(in: 5.0...10.0) // Chute lente à modérée
            )
            // Ajouter avec un délai pour éviter l'encombrement instantané
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...0.5)) {
                self.fallingPoops.append(newPoop)
            }
        }
    }
    
    /**
     Démarre le timer pour faire chuter les particules et les nettoyer.
     */
    func startFallingPoopTimer() {
        self.fallingPoopTimer?.invalidate()
        
        let updateRate = 1.0 / 30.0 // Mettre à jour 30 fois par seconde (30 FPS)
        let speedFactor: CGFloat = 50.0 // Vitesse de base en points/seconde
        
        self.fallingPoopTimer = Timer.scheduledTimer(withTimeInterval: updateRate, repeats: true) { _ in
            
            let screenHeight = UIScreen.main.bounds.height
            
            // Mettre à jour la position de chaque particule
            for index in self.fallingPoops.indices {
                
                let poop = self.fallingPoops[index]
                
                // Calcul du déplacement vertical basé sur la durée et la vitesse
                let travel = CGFloat(speedFactor / poop.duration) * CGFloat(updateRate) * 100 // Ajustement
                
                self.fallingPoops[index].y += travel
                
            }
            
            // Nettoyer les particules qui sont sorties de l'écran
            self.fallingPoops.removeAll { $0.y > screenHeight * 1.5 }
        }
    }
    
} // FIN DE ContentView

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
