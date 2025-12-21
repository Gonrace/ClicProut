import SwiftUI

// MARK: - VUE INVENTAIRE
struct InventoryView: View {
    @ObservedObject var data: GameData
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab: InventoryCategory = .functional
    
    enum InventoryCategory: String {
        case functional = "Ma Progression"
        case cosmetics = "Mon Style"
    }
    
    // 1. Filtre les objets fonctionnels (Production, Outils, Améliorations)
    var ownedFunctionalItems: [ShopItem] {
        data.allItems.filter { item in
            let isFunctional = (
                item.category == .production ||
                item.category == .amelioration ||
                item.category == .outil ||
                item.category == .jalonNarratif
            )
            return data.itemLevels[item.name, default: 0] > 0 && isFunctional
        }
    }
    
    // 2. Filtre TOUS les cosmétiques (Peu importe le type, tant que c'est visuel/auditif)
    var ownedCosmeticItems: [ShopItem] {
        data.allItems.filter { item in
            let isCosmetic = (
                item.category == .skin ||
                item.category == .sound ||
                item.category == .background
            )
            return data.itemLevels[item.name, default: 0] > 0 && isCosmetic
        }
    }
    
    var body: some View {
        ZStack {
            // Utilisation de ton StyleConstants
            AppStyle.primaryBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Utilisation de ta CustomTitleBar unifiée
                CustomTitleBar(title: "Mes Objets 🗃️", onDismiss: { dismiss() })
                
                // Sélecteur d'onglet
                Picker("Type", selection: $selectedTab) {
                    Text(InventoryCategory.functional.rawValue).tag(InventoryCategory.functional)
                    Text(InventoryCategory.cosmetics.rawValue).tag(InventoryCategory.cosmetics)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppStyle.defaultPadding)
                .padding(.bottom, AppStyle.defaultPadding)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        
                        if selectedTab == .functional {
                            if !ownedFunctionalItems.isEmpty {
                                ForEach(1...5, id: \.self) { acteNum in
                                    let itemsInActe = ownedFunctionalItems.filter { $0.acte == acteNum }
                                    if !itemsInActe.isEmpty {
                                        InventorySection(title: acteTitle(for: acteNum)) {
                                            ForEach(itemsInActe, id: \.name) { item in
                                                InventoryRow(item: item, data: data)
                                            }
                                        }
                                    }
                                }
                            } else {
                                Text("Vous n'avez pas encore d'objets de progression.")
                                    .inventoryEmptyText()
                            }
                            
                        } else {
                            // ONGLET STYLE : On affiche tout en vrac
                            if !ownedCosmeticItems.isEmpty {
                                InventorySection(title: "Personnalisation") {
                                    ForEach(ownedCosmeticItems, id: \.name) { item in
                                        CosmeticRow(item: item, data: data)
                                    }
                                }
                            } else {
                                Text("Aucun style débloqué pour le moment.")
                                    .inventoryEmptyText()
                            }
                        }
                    }
                    .padding(.horizontal, AppStyle.defaultPadding)
                }
            }
        }
    }
    
    func acteTitle(for acte: Int) -> String {
        return data.actesInfo[acte]?.title ?? "Acte \(acte)"
        }
    }

// MARK: - COMPOSANTS INTERNES UTILISANT APPSTYLE

struct InventorySection<Content: View>: View {
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
                .foregroundColor(AppStyle.accentColor)
                .padding(.leading, 5)
            
            VStack(spacing: 1) {
                content
            }
            .background(AppStyle.listRowBackground)
            .cornerRadius(12)
        }
    }
}

struct InventoryRow: View {
    let item: ShopItem
    @ObservedObject var data: GameData
    
    var body: some View {
        HStack {
            Text(item.emoji).font(.largeTitle)
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
            }
            
            Spacer()
            
            if item.category == .production || item.category == .outil {
                Text("Lv. \(data.itemLevels[item.name, default: 0])")
                    .fontWeight(.bold)
                    .foregroundColor(AppStyle.accentColor)
            } else {
                Text("Acquis ✅")
                    .font(.caption)
                    .foregroundColor(AppStyle.positiveColor)
            }
        }
        .padding(12)
        .background(AppStyle.listRowBackground)
    }
}

struct CosmeticRow: View {
    let item: ShopItem
    @ObservedObject var data: GameData
    
    var body: some View {
        HStack {
            Text(item.emoji).font(.largeTitle)
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.white)
                // Affiche la catégorie brute du CSV (skin, sound, etc.)
                Text(item.category.rawValue.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(4)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("Débloqué")
                .font(.caption)
                .foregroundColor(AppStyle.positiveColor)
        }
        .padding(12)
        .background(AppStyle.listRowBackground)
    }
}

extension View {
    func inventoryEmptyText() -> some View {
        self.font(AppStyle.bodyFont)
            .foregroundColor(AppStyle.secondaryTextColor)
            .padding(.top, 40)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
