import SwiftUI

// MARK: - VUE INVENTAIRE
struct InventoryView: View {
    @ObservedObject var data: GameData
    @Environment(\.dismiss) var dismiss
    
    // On passe à 3 onglets
    @State private var selectedTab: InventoryTab = .objects
    
    enum InventoryTab: String, CaseIterable {
        case objects = "Mes Objets"
        case story = "Mon Histoire"
        case cosmetics = "Mon Style"
    }
    
    // --- LOGIQUE DE FILTRAGE ---
    
    // 1. Objets techniques (Production, Outils, Améliorations)
    var ownedFunctionalItems: [ShopItem] {
        let allItems = data.cloudManager?.allItems ?? []
        return allItems.filter { item in
            let isTech = (item.category == .production || item.category == .outil || item.category == .amelioration)
            return data.itemLevels[item.name, default: 0] > 0 && isTech
        }
    }
    
    // 2. Histoire (Jalons narratifs uniquement)
    var ownedStoryItems: [ShopItem] {
        let allItems = data.cloudManager?.allItems ?? []
        return allItems.filter { item in
            return data.itemLevels[item.name, default: 0] > 0 && item.category == .jalonNarratif
        }
    }
    
    // 3. Cosmétiques (Skins, Sounds, Backgrounds)
    var ownedCosmeticItems: [ShopItem] {
        let allItems = data.cloudManager?.allItems ?? []
        return allItems.filter { item in
            let isCosmetic = (item.category == .skin || item.category == .sound || item.category == .background)
            return data.itemLevels[item.name, default: 0] > 0 && isCosmetic
        }
    }
    
    var body: some View {
        ZStack {
            AppStyle.primaryBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Barre de titre unifiée
                CustomTitleBar(title: "Inventaire 🗃️", onDismiss: { dismiss() })
                
                // Picker à 3 segments
                Picker("Catégorie", selection: $selectedTab) {
                    ForEach(InventoryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppStyle.defaultPadding)
                .padding(.bottom, AppStyle.defaultPadding)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        
                        switch selectedTab {
                        case .objects:
                            renderObjectsTab()
                        case .story:
                            renderStoryTab()
                        case .cosmetics:
                            renderCosmeticsTab()
                        }
                    }
                    .padding(.horizontal, AppStyle.defaultPadding)
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    // --- VUES DES ONGLETS ---
    
    @ViewBuilder
    private func renderObjectsTab() -> some View {
        if ownedFunctionalItems.isEmpty {
            emptyStateView(text: "Aucun objet de production possédé.")
        } else {
            ForEach(1...5, id: \.self) { acteNum in
                let itemsInActe = ownedFunctionalItems.filter { $0.acte == acteNum }
                if !itemsInActe.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(acteTitle(for: acteNum))
                            .font(AppStyle.subTitleFont)
                            .fontWeight(.bold)
                            .foregroundColor(AppStyle.accentColor)
                        
                        // Tri par sous-catégorie pour plus de clarté
                        subGroup(title: "Outils & Clics", items: itemsInActe.filter { $0.category == .outil })
                        subGroup(title: "Bâtiments & Production", items: itemsInActe.filter { $0.category == .production })
                        subGroup(title: "Améliorations", items: itemsInActe.filter { $0.category == .amelioration })
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func renderStoryTab() -> some View {
        if ownedStoryItems.isEmpty {
            emptyStateView(text: "Votre légende n'a pas encore commencé...")
        } else {
            ForEach(1...5, id: \.self) { acteNum in
                let jalons = ownedStoryItems.filter { $0.acte == acteNum }
                if !jalons.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(acteTitle(for: acteNum))
                            .font(AppStyle.subTitleFont)
                            .fontWeight(.bold)
                            .foregroundColor(AppStyle.accentColor)
                        
                        VStack(spacing: 1) {
                            ForEach(jalons, id: \.name) { jalon in
                                InventoryRow(item: jalon, data: data)
                            }
                        }
                        .background(AppStyle.listRowBackground)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func renderCosmeticsTab() -> some View {
        if ownedCosmeticItems.isEmpty {
            emptyStateView(text: "Aucun objet de style débloqué.")
        } else {
            VStack(spacing: 1) {
                ForEach(ownedCosmeticItems, id: \.name) { item in
                    CosmeticRow(item: item, data: data)
                }
            }
            .background(AppStyle.listRowBackground)
            .cornerRadius(12)
        }
    }
    
    // --- COMPOSANTS DE STRUCTURE ---
    
    @ViewBuilder
    private func subGroup(title: String, items: [ShopItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.leading, 10)
                
                VStack(spacing: 1) {
                    ForEach(items, id: \.name) { item in
                        InventoryRow(item: item, data: data)
                    }
                }
                .background(AppStyle.listRowBackground)
                .cornerRadius(12)
            }
        }
    }
    
    private func emptyStateView(text: String) -> some View {
        Text(text)
            .font(AppStyle.bodyFont)
            .foregroundColor(AppStyle.secondaryTextColor)
            .padding(.top, 40)
            .frame(maxWidth: .infinity, alignment: .center)
    }
    
    func acteTitle(for acte: Int) -> String {
        return data.cloudManager?.actesInfo[acte]?.title ?? "Acte \(acte)"
    }
}

// MARK: - LIGNES D'INVENTAIRE (REUTILISABLES)

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
                    .lineLimit(2)
            }
            
            Spacer()
            
            if item.category == .production || item.category == .outil {
                Text("Lv. \(data.itemLevels[item.name, default: 0])")
                    .fontWeight(.bold)
                    .foregroundColor(AppStyle.accentColor)
            } else {
                Image(systemName: "checkmark.seal.fill")
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
                
                Text(item.category.rawValue.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppStyle.accentColor.opacity(0.2))
                    .cornerRadius(4)
                    .foregroundColor(AppStyle.accentColor)
            }
            
            Spacer()
            
            Text("ÉQUIPÉ") // Optionnel: tu pourrais ajouter une logique de sélection ici
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(AppStyle.positiveColor)
        }
        .padding(12)
        .background(AppStyle.listRowBackground)
    }
}
