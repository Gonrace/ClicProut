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
                
                // Score en temps réel
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
                            // --- ONGLET PRODUCTION (ACTES) ---
                            ActeSection(title: "Acte I : Les Débuts 👶", acte: 1, data: data)
                            
                            if data.isActeUnlocked(2) {
                                ActeSection(title: "Acte II : La Croissance 😈", acte: 2, data: data)
                            } else {
                                LockedActeRow(acteNumber: 1)
                            }
                            
                            if data.isActeUnlocked(3) {
                                ActeSection(title: "Acte III : L'Amour ❤️", acte: 3, data: data)
                            } else if data.isActeUnlocked(2) {
                                LockedActeRow(acteNumber: 2)
                            }
                            
                            if data.isActeUnlocked(4) {
                                ActeSection(title: "Acte IV : L'Héritage 🌌", acte: 4, data: data)
                            } else if data.isActeUnlocked(3) {
                                LockedActeRow(acteNumber: 3)
                            }
                            
                            if data.isActeUnlocked(5) {
                                ActeSection(title: "Acte V : Le Grand Repos 👴", acte: 5, data: data)
                            } else if data.isActeUnlocked(4) {
                                LockedActeRow(acteNumber: 4)
                            }

                        } else if selectedTab == .cosmetics {
                            // --- ONGLET COSMÉTIQUES (FILTRÉS PAR ACTE) ---
                            ForEach(1...5, id: \.self) { acteNum in
                                if data.isActeUnlocked(acteNum) {
                                    ShopSection(title: "Style - Acte \(acteNum)") {
                                        ForEach(cosmeticShopItems.filter { $0.acte == acteNum }, id: \.name) { item in
                                            if data.itemLevels[item.name, default: 0] > 0 {
                                                ItemBoughtRow(item: item)
                                            } else {
                                                ItemRow(item: item, data: data)
                                            }
                                        }
                                    }
                                }
                            }
                        } else if selectedTab == .currency {
                            // --- ONGLET PQ D'OR ---
                            IAPShopView(data: data)
                        }
                    }
                    .padding(.horizontal, AppStyle.defaultPadding)
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

// MARK: - COMPOSANTS INTERNES
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

// MARK: - COMPOSANT DE SECTION PAR ACTE (MIS À JOUR)
struct ActeSection: View {
    let title: String
    let acte: Int
    @ObservedObject var data: GameData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Titre de l'Acte
            Text(title)
                .font(AppStyle.subTitleFont)
                .bold()
                .foregroundColor(.white)
                .padding(.leading, 5)
            
            // --- GROUPE 1 : OUTILS DE CLIC ---
            categoryGroup(
                title: "Outils de Clic 🖱️",
                items: standardShopItems.filter { $0.acte == acte && $0.category == .outil }
            )
            
            // --- GROUPE 2 : BÂTIMENTS DE PRODUCTION ---
            categoryGroup(
                title: "Bâtiments de Production 🏭",
                items: standardShopItems.filter { $0.acte == acte && $0.category == .production }
            )
            
            // --- GROUPE 3 : AMÉLIORATIONS & JALONS ---
            categoryGroup(
                title: "Améliorations & Jalons ✨",
                items: standardShopItems.filter { $0.acte == acte && ($0.category == .amelioration || $0.category == .jalonNarratif) }
            )
        }
        .padding(.bottom, 10)
    }
    
    // Fonction helper pour créer les sous-sections
    @ViewBuilder
    private func categoryGroup(title: String, items: [ShopItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .padding(.leading, 10)
                    .textCase(.uppercase)
                
                VStack(spacing: 1) {
                    ForEach(items, id: \.name) { item in
                        let level = data.itemLevels[item.name, default: 0]
                        let isUnique = (item.category != .production && item.category != .outil)
                        
                        if isUnique && level > 0 && !item.isConsumable {
                            ItemBoughtRow(item: item)
                        } else {
                            ItemRow(item: item, data: data)
                        }
                    }
                }
                .background(AppStyle.listRowBackground)
                .cornerRadius(12)
            }
        }
    }
}
struct LockedActeRow: View {
    let acteNumber: Int
    var body: some View {
        HStack {
            Image(systemName: "lock.fill").foregroundColor(.orange)
            Text("Terminez 90% de l'Acte \(acteNumber) pour débloquer la suite")
                .font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding().background(Color.white.opacity(0.05)).cornerRadius(10)
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
    
    var hasRequiredItems: Bool {
        guard let reqName = item.requiredItem, let reqCount = item.requiredItemCount else { return true }
        return data.itemLevels[reqName, default: 0] >= reqCount
    }
    
    var canAfford: Bool {
        item.currency == .pets ? data.totalFartCount >= displayCost : data.goldenToiletPaper >= displayCost
    }
    
    var body: some View {
        HStack {
            Text(item.emoji).font(.largeTitle)
                .grayscale(hasRequiredItems ? 0 : 1).opacity(hasRequiredItems ? 1 : 0.5)
            
            VStack(alignment: .leading) {
                HStack {
                    Text(item.name).font(.headline).foregroundColor(hasRequiredItems ? .white : .gray)
                    if item.category == .production || item.category == .outil {
                        Text("Lv.\(data.itemLevels[item.name, default: 0])").font(.system(size: 10)).foregroundColor(.cyan).bold()
                    }
                }
                if !hasRequiredItems {
                    Text("Requis: \(item.requiredItemCount ?? 0)x \(item.requiredItem ?? "")").font(.caption2).foregroundColor(.red).bold()
                } else {
                    Text(item.description).font(.caption).foregroundColor(.gray).lineLimit(2)
                }
            }
            Spacer()
            Button(action: {
                if data.attemptPurchase(item: item) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }) {
                VStack {
                    Text("\(displayCost)").bold()
                    Text(item.currency == .goldenPaper ? "👑" : "💩").font(.caption2)
                }
                .padding(8).frame(width: 80).background(hasRequiredItems && canAfford ? Color.green : Color.gray.opacity(0.5)).foregroundColor(.white).cornerRadius(8)
            }
            .disabled(!canAfford || !hasRequiredItems)
        }.padding(10)
    }
}

struct ItemBoughtRow: View {
    let item: ShopItem
    var body: some View {
        HStack {
            Text(item.emoji).font(.largeTitle).opacity(0.5)
            VStack(alignment: .leading) {
                Text(item.name).font(.headline).foregroundColor(.gray)
                Text("Déjà acquis").font(.caption).foregroundColor(.green)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        }.padding(10)
    }
}

struct IAPShopView: View {
    @ObservedObject var data: GameData
    let packs = [("Petit Rouleau", 10, "0.99€"), ("Pack Confort", 60, "4.99€"), ("Super Rouleau Famille", 150, "9.99€")]
    var body: some View {
        VStack(spacing: 15) {
            ForEach(packs, id: \.0) { pack in
                HStack {
                    Text("👑").font(.title)
                    VStack(alignment: .leading) {
                        Text(pack.0).bold().foregroundColor(.white)
                        Text("\(pack.1) PQ d'Or").font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                    Button(pack.2) { data.goldenToiletPaper += pack.1 }.buttonStyle(.borderedProminent).tint(.orange)
                }.padding().background(AppStyle.listRowBackground).cornerRadius(12)
            }
        }
    }
}
