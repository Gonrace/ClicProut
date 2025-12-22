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
                            // On récupère les IDs d'actes depuis le CloudManager
                            let sortedActeIDs = data.cloudManager?.actesInfo.keys.sorted() ?? [1]
                            
                            ForEach(sortedActeIDs, id: \.self) { acteID in
                                if let info = data.cloudManager?.actesInfo[acteID] {
                                    if data.isActeUnlocked(acteID) {
                                        ActeSection(title: info.title, acte: acteID, data: data)
                                    } else {
                                        if acteID == 1 || data.isActeUnlocked(acteID - 1) {
                                            LockedActeRow(acteNumber: acteID)
                                        }
                                    }
                                }
                            }

                        } else if selectedTab == .cosmetics {
                            let allItems = data.cloudManager?.allItems ?? []
                            let cosmetics = allItems.filter {
                                $0.category == .skin || $0.category == .sound || $0.category == .background
                            }.sorted {
                                if $0.acte != $1.acte { return $0.acte < $1.acte }
                                return $0.baseCost < $1.baseCost
                            }
                            
                            if !cosmetics.isEmpty {
                                ShopSection(title: "Personnalisation") {
                                    ForEach(cosmetics, id: \.name) { item in
                                        if data.itemLevels[item.name, default: 0] > 0 {
                                            ItemBoughtRow(item: item)
                                        } else {
                                            ItemRow(item: item, data: data)
                                        }
                                    }
                                }
                            }
                        } else if selectedTab == .currency {
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

struct ActeSection: View {
    let title: String
    let acte: Int
    @ObservedObject var data: GameData
    
    var body: some View {
        let allItems = data.cloudManager?.allItems ?? []
        
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(AppStyle.subTitleFont)
                .bold()
                .foregroundColor(.white)
                .padding(.leading, 5)
            
            categoryGroup(
                title: "Outils de Clic 🖱️",
                items: allItems.filter { $0.acte == acte && $0.category == .outil }
                    .sorted(by: { $0.baseCost < $1.baseCost })
            )
            
            categoryGroup(
                title: "Bâtiments de Production 🏭",
                items: allItems.filter { $0.acte == acte && $0.category == .production }
                    .sorted(by: { $0.baseCost < $1.baseCost })
            )
            
            categoryGroup(
                title: "Améliorations ✨",
                items: allItems.filter { $0.acte == acte && $0.category == .amelioration}
                    .sorted(by: { $0.baseCost < $1.baseCost })
            )
            categoryGroup(
                title: "Jalons 📚",
                items: allItems.filter { $0.acte == acte && $0.category == .jalonNarratif }
                    .sorted(by: { $0.baseCost < $1.baseCost })
            )
        }
        .padding(.bottom, 10)
    }
    
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
            Text("Terminez l'Acte \(acteNumber - 1) pour débloquer la suite")
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
            let mult = data.cloudManager?.config.priceMultiplier ?? 1.15
            return Int((Double(item.baseCost) * pow(mult, Double(level))).rounded())
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
