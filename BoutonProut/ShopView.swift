import SwiftUI

// NOTE: Le code de ShopItem et shopItems doit être dans votre GameData.swift ou un fichier global.

struct ShopView: View {
    
    @ObservedObject var data: GameData
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Utilisation de la constante de fond unifiée
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 1. BARRE DE TITRE PERSONNALISÉE (Unifiée)
                CustomTitleBar(title: "La Proutique 🛍️", onDismiss: { dismiss() })
                
                // Affichage du score en haut (Très réactif)
                Text("Actuellement : \(data.totalFartCount) 💩")
                    .font(.headline)
                    .foregroundColor(AppStyle.accentColor) // Utilisation de la constante
                    .padding(.bottom, AppStyle.defaultPadding)
                
                // 2. CONTENU DU MAGASIN (Scrollable)
                ScrollView {
                    VStack(alignment: .leading, spacing: AppStyle.defaultPadding) {
                        
                        // --- SECTION 1 : OUTILS DE CLIC ---
                        ShopSection(title: "Outils de Clic (Manuel)") {
                            ForEach(shopItems.filter { $0.type == .clicker }) { item in
                                ItemRow(item: item, data: data)
                            }
                        }
                        
                        // --- SECTION 2 : BÂTIMENTS ---
                        ShopSection(title: "Bâtiments (Automatique)") {
                            ForEach(shopItems.filter { $0.type == .building }) { item in
                                ItemRow(item: item, data: data)
                            }
                        }
                        
                        // --- SECTION 3 : AMÉLIORATIONS (RARES) ---
                        ShopUpgradesSection(data: data)
                    }
                    .padding(.horizontal, AppStyle.defaultPadding)
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

// --- STRUCTURE D'AIDE pour les sections ---
struct ShopSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppStyle.subTitleFont)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.leading, 5)
            
            VStack(spacing: 1) {
                content
            }
            .background(AppStyle.listRowBackground)
            .cornerRadius(10)
        }
    }
}

// --- STRUCTURE D'AIDE pour les UPGRADES ---
struct ShopUpgradesSection: View {
    @ObservedObject var data: GameData
    
    var body: some View {
        let upgrades = shopItems.filter { $0.type == .upgrade }
        if !upgrades.isEmpty {
            ShopSection(title: "Améliorations Uniques") {
                ForEach(upgrades) { item in
                    if data.autoFarterLevels[item.name, default: 0] == 0 {
                        ItemRow(item: item, data: data)
                    } else {
                        HStack {
                            Text(item.emoji).font(.largeTitle)
                            VStack(alignment: .leading) {
                                Text(item.name).font(.headline).foregroundColor(.white)
                                Text(item.description).font(.caption).foregroundColor(.orange)
                            }
                            Spacer()
                            Text("ACHETÉ ✅").foregroundColor(AppStyle.positiveColor).font(.caption)
                        }
                        .padding(8)
                        .background(AppStyle.listRowBackground)
                        .cornerRadius(10) // Ajouté pour l'homogénéité
                    }
                }
            }
        }
    }
}


// ItemRow (La rangée individuelle)
struct ItemRow: View {
    let item: ShopItem
    @ObservedObject var data: GameData
    
    var currentLevel: Int {
        return data.autoFarterLevels[item.name, default: 0]
    }
    
    var calculatedCost: Int {
        if item.type == .upgrade {
            return item.baseCost
        } else {
            let cost = Double(item.baseCost) * pow(1.2, Double(currentLevel))
            return Int(cost.rounded())
        }
    }
    
    var canAfford: Bool { data.totalFartCount >= calculatedCost }
    var isUnlocked: Bool { data.totalFartCount >= item.unlockThreshold }
    
    var isAvailable: Bool {
        if !isUnlocked { return false }
        if let req = item.requiredItem {
            return data.autoFarterLevels[req, default: 0] > 0
        }
        return true
    }
    
    func buyItem() {
        guard canAfford && isAvailable && isUnlocked else { return }
        data.totalFartCount -= calculatedCost
        data.autoFarterLevels[item.name, default: 0] += 1
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    var body: some View {
        HStack {
            Text(item.emoji).font(.largeTitle)
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .strikethrough(!isUnlocked, color: AppStyle.warningColor)
                
                // Description différente selon le type
                if item.type == .upgrade {
                    Text(item.description).font(.caption).foregroundColor(.orange)
                } else if item.type == .building {
                    Text("\(String(format: "%.1f", item.dpsRate / 10.0)) PPS | Niv: \(currentLevel)")
                        .font(.caption).foregroundColor(AppStyle.secondaryTextColor)
                } else {
                    Text("+\(item.clickMultiplier) Clics | Niv: \(currentLevel)")
                        .font(.caption).foregroundColor(AppStyle.secondaryTextColor)
                }
                
                if !isUnlocked {
                    Text("Débloque à \(item.unlockThreshold) pets").font(.caption).foregroundColor(AppStyle.warningColor)
                } else if !isAvailable {
                    Text("Nécessite l'objet requis").font(.caption).foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            Button(action: buyItem) {
                Text("\(calculatedCost)")
                    .font(.system(size: 14, weight: .bold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(canAfford && isAvailable && isUnlocked ? AppStyle.positiveColor : AppStyle.secondaryButtonColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!canAfford || !isAvailable || !isUnlocked)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(AppStyle.listRowBackground.opacity(0.8)) // Utilisation du fond de ligne
        .opacity(isUnlocked && isAvailable ? 1.0 : 0.6)
    }
}
