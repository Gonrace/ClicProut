import SwiftUI

struct ShopView: View {
    @ObservedObject var data: GameData
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab: ShopCategory = .tools
    
    enum ShopCategory: String {
        case tools = "Production"
        case cosmetics = "Cosmétiques"
        case currency = "PQ d'Or 👑"
    }
    
    var body: some View {
        ZStack {
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 1. BARRE DE TITRE
                CustomTitleBar(title: "La Proutique 🛍️", onDismiss: { dismiss() })
                
                // Score
                HStack(spacing: 20) {
                    Text("Pets : \(data.totalFartCount) 💩")
                        .font(.headline).foregroundColor(.white)
                    Text("PQ d'Or : \(data.goldenToiletPaper) 👑")
                        .font(.headline).foregroundColor(AppStyle.accentColor)
                }
                .padding(.bottom, AppStyle.defaultPadding)
                
                // 2. SÉLECTEUR DE CATÉGORIE
                Picker("Catégorie", selection: $selectedTab) {
                    Text(ShopCategory.tools.rawValue).tag(ShopCategory.tools)
                    Text(ShopCategory.cosmetics.rawValue).tag(ShopCategory.cosmetics)
                    Text(ShopCategory.currency.rawValue).tag(ShopCategory.currency)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppStyle.defaultPadding)
                .padding(.bottom, AppStyle.defaultPadding)
                
                // 3. CONTENU DÉFILANT
                ScrollView {
                    VStack(alignment: .leading, spacing: AppStyle.defaultPadding) {
                        
                        if selectedTab == .tools {
                            // --- ONGLET PRODUCTION ---
                            ShopSection(title: "1. Outils de Clic (PPC)") {
                                ForEach(standardShopItems.filter { $0.category == .outil }, id: \.id) { item in
                                    ItemRow(item: item, data: data)
                                }
                            }
                            
                            ShopSection(title: "2. Bâtiments (PPS)") {
                                ForEach(standardShopItems.filter { $0.category == .production }, id: \.id) { item in
                                    ItemRow(item: item, data: data)
                                }
                            }
                            
                            ShopUniqueSection(data: data, title: "3. Améliorations Permanente", category: .amelioration)
                            
                            ShopUniqueSection(data: data, title: "4. Progression", category: .jalonNarratif)
                            
                        } else if selectedTab == .cosmetics {
                            // --- ONGLET COSMÉTIQUES ---
                            if !cosmeticShopItems.isEmpty {
                                ShopSection(title: "Personnalisation") {
                                    ForEach(cosmeticShopItems, id: \.id) { item in
                                        // Correction ici pour l'affichage des cosmétiques déjà achetés
                                        if data.itemLevels[item.name, default: 0] > 0 {
                                            ItemBoughtRow(item: item)
                                        } else {
                                            ItemRow(item: item, data: data)
                                        }
                                    }
                                }
                            } else {
                                Text("Aucun cosmétique disponible pour le moment.")
                                    .foregroundColor(.gray).padding()
                            }
                            
                        } else if selectedTab == .currency {
                            // --- ONGLET ACHAT PQ D'OR ---
                            IAPShopView(data: data)
                        }
                    }
                    .padding(.horizontal, AppStyle.defaultPadding)
                    .padding(.bottom, 50)
                }
            }
        }
    }
    
    // --- COMPOSANTS INTERNES (Gardés au sein de ShopView pour la cohérence) ---
    
    struct ShopUniqueSection: View {
        @ObservedObject var data: GameData
        let title: String
        let category: ItemCategory
        var body: some View {
            let items = standardShopItems.filter { $0.category == category }
            if !items.isEmpty {
                ShopSection(title: title) {
                    ForEach(items, id: \.id) { item in
                        if data.itemLevels[item.name, default: 0] > 0 && !item.isConsumable {
                            ItemBoughtRow(item: item)
                        } else {
                            ItemRow(item: item, data: data)
                        }
                    }
                }
            }
        }
    }

    struct ItemBoughtRow: View {
        let item: ShopItem
        var body: some View {
            HStack {
                Text(item.emoji).font(.largeTitle)
                VStack(alignment: .leading) {
                    Text(item.name).font(.headline).foregroundColor(.white)
                    Text(item.description).font(.caption).foregroundColor(.gray)
                }
                Spacer()
                Text("POSSÉDÉ ✅").foregroundColor(.green).font(.caption).fontWeight(.bold)
            }
            .padding(8).background(AppStyle.listRowBackground).cornerRadius(10)
        }
    }

    struct ShopSection<Content: View>: View {
        let title: String
        let content: Content
        init(title: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
        }
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(AppStyle.subTitleFont).bold().foregroundColor(.white).padding(.leading, 5)
                VStack(spacing: 1) { content }.background(AppStyle.listRowBackground).cornerRadius(10)
            }
        }
    }

    struct ItemRow: View {
        let item: ShopItem
        @ObservedObject var data: GameData
        
        var displayCost: Int {
            let level = data.itemLevels[item.name, default: 0]
            if item.category == .production || item.category == .outil {
                return Int((Double(item.baseCost) * pow(1.2, Double(level))).rounded())
            }
            return item.baseCost
        }
        
        var body: some View {
            HStack {
                Text(item.emoji).font(.largeTitle)
                VStack(alignment: .leading) {
                    HStack(spacing: 5) {
                        Text(item.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        // Ajout du niveau à côté du nom
                        if item.category == .production || item.category == .outil {
                            Text("Niv. \(data.itemLevels[item.name, default: 0])")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 4)
                                .background(Color.blue.opacity(0.3))
                                .cornerRadius(4)
                                .foregroundColor(.cyan)
                        }
                    }
                    Text(item.category == .production ? "\(String(format: "%.1f", item.dpsRate / 10.0)) PPS" : item.description)
                        .font(.caption).foregroundColor(.gray)
                }
                Spacer()
                Button(action: {
                    // 1. On tente l'achat
                    let success = data.attemptPurchase(item: item)
                    
                    // 2. On déclenche le retour haptique (vibration) selon le résultat
                    if success {
                        // Vibration légère et joyeuse pour le succès
                        let successGenerator = UINotificationFeedbackGenerator()
                        successGenerator.notificationOccurred(.success)
                    } else {
                        // Vibration double et sèche pour l'échec (pas assez d'argent)
                        let errorGenerator = UINotificationFeedbackGenerator()
                        errorGenerator.notificationOccurred(.error)
                    }
                }) {
                    // Ton label de bouton actuel (VStack avec le prix et l'emoji)
                    VStack {
                        Text("\(displayCost)").bold()
                        Text(item.currency == .goldenPaper ? "👑" : "💩").font(.caption2)
                    }
                    .padding(8)
                    .background(canAfford ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!canAfford)
            }
            .padding(10)
        }
        
        var canAfford: Bool {
            if item.currency == .pets {
                return data.totalFartCount >= displayCost
            } else {
                return data.goldenToiletPaper >= displayCost
            }
        }
    }
    
    struct IAPShopView: View {
        @ObservedObject var data: GameData
        let iapPacks = [("Petit Rouleau", "0.99€", 10), ("Pack Confort", "4.99€", 60), ("Super Rouleau Famille", "9.99€", 150)]
        var body: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("Banque de PQ d'Or").font(.headline).foregroundColor(.white)
                ForEach(iapPacks, id: \.0) { pack in
                    HStack {
                        Text("👑").font(.title2)
                        VStack(alignment: .leading) {
                            Text(pack.0).foregroundColor(.white).bold()
                            Text("\(pack.2) PQ d'Or").font(.caption).foregroundColor(.gray)
                        }
                        Spacer()
                        Button(pack.1) { data.goldenToiletPaper += pack.2 }
                            .padding(8).background(Color.yellow).foregroundColor(.black).cornerRadius(8)
                    }
                    .padding().background(AppStyle.listRowBackground).cornerRadius(10)
                }
            }
        }
    }
}
