import SwiftUI

// NOTE: Nécessite ShopModels.swift pour les structures ShopItem et ItemCategory.
//       Nécessite StyleConstants.swift pour AppStyle et CustomTitleBar.

struct InventoryView: View {
    @ObservedObject var data: GameData
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab: InventoryCategory = .functional
    
    enum InventoryCategory: String {
        case functional = "Outils & Bâtiments"
        case cosmetics = "Cosmétiques"
    }
    
    // Filtre les objets possédés fonctionnels (Inclut Défense, Attaque, Jalon)
    var ownedFunctionalItems: [ShopItem] {
        return data.allItems.filter { item in
            let isFunctional = (
                item.category == .production ||
                item.category == .amelioration ||
                item.category == .outil ||
                item.category == .jalonNarratif
            )
            return data.itemLevels[item.name, default: 0] > 0 && isFunctional
        }
    }
    
    // Filtre les objets possédés cosmétiques
    var ownedCosmeticItems: [ShopItem] {
        return data.allItems.filter { item in
            let isCosmetic = (item.category == .skin || item.category == .sound || item.category == .background || item.category == .music)
            return data.itemLevels[item.name, default: 0] > 0 && isCosmetic
        }
    }
    
    var body: some View {
        ZStack {
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                CustomTitleBar(title: "Mes Objets 🗃️", onDismiss: { dismiss() })
                
                // SÉLECTION D'ONGLET
                Picker("Type d'Inventaire", selection: $selectedTab) {
                    Text(InventoryCategory.functional.rawValue).tag(InventoryCategory.functional)
                    Text(InventoryCategory.cosmetics.rawValue).tag(InventoryCategory.cosmetics)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppStyle.defaultPadding)
                .padding(.bottom, AppStyle.defaultPadding)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppStyle.defaultPadding) {
                        
                        if selectedTab == .functional {
                            
                            if !ownedFunctionalItems.isEmpty {
                                
                                // 1. Bâtiments (PPS)
                                                        InventorySection(title: "Bâtiments (Auto-Pets)") {
                                                            ForEach(ownedFunctionalItems.filter { $0.category == .production }, id: \.id) { item in
                                                                InventoryRow(item: item, data: data)
                                                            }
                                                        }
                                                        
                                                        // 2. Outils de Clic (PPC)
                                                        InventorySection(title: "Outils de Clic (PPC)") {
                                                            ForEach(ownedFunctionalItems.filter { $0.category == .outil }, id: \.id) { item in
                                                                InventoryRow(item: item, data: data)
                                                            }
                                                        }
                                                        
                                                        // 3. Améliorations (Bonus Passifs)
                                                        InventorySection(title: "Améliorations Multiplicatrices") {
                                                            ForEach(ownedFunctionalItems.filter { $0.category == .amelioration }, id: \.id) { item in
                                                                InventoryRow(item: item, data: data)
                                                            }
                                                        }
                                                        
                                                        // 4. Défense (Protection)
                                                        InventorySection(title: "Défense (Anti-Attaque)") {
                                                            ForEach(ownedFunctionalItems.filter { $0.category == .defense }, id: \.id) { item in
                                                                InventoryRow(item: item, data: data)
                                                            }
                                                        }
                                                        
                                                        // 5. Attaque / Perturbateur
                                                        InventorySection(title: "Armes & Perturbateurs (PvP)") {
                                                            ForEach(ownedFunctionalItems.filter { $0.category == .perturbateur }, id: \.id) { item in
                                                                InventoryRow(item: item, data: data)
                                                            }
                                                        }
                                                        
                                                        // 6. Jalons Narratifs
                                                        InventorySection(title: "Progression & Jalons de Vie") {
                                                            ForEach(ownedFunctionalItems.filter { $0.category == .jalonNarratif }, id: \.id) { item in
                                                                InventoryRow(item: item, data: data)
                                                            }
                                                        }
                                
                            } else {
                                Text("Vous n'avez pas encore d'outils de production.")
                                    .inventoryEmptyText()
                            }
                            
                        } else if selectedTab == .cosmetics {
                            
                            if !ownedCosmeticItems.isEmpty {
                                
                                InventorySection(title: "Personnalisation") {
                                    ForEach(ownedCosmeticItems, id: \.id) { item in
                                        CosmeticRow(item: item, data: data)
                                    }
                                }
                            } else {
                                Text("Vous n'avez pas encore débloqué de cosmétiques.")
                                    .inventoryEmptyText()
                            }
                        }
                        
                        if ownedFunctionalItems.isEmpty && ownedCosmeticItems.isEmpty {
                            Text("Votre inventaire est entièrement vide. Achetez quelque chose à la Proutique !")
                                .inventoryEmptyText()
                        }
                    }
                    .padding(AppStyle.defaultPadding)
                }
            }
        }
    }
}

// --- STRUCTURES D'AIDE pour l'inventaire ---

// Helper pour le texte vide (réduction de la redondance)
extension View {
    func inventoryEmptyText() -> some View {
        self
        .foregroundColor(AppStyle.secondaryTextColor)
        .padding(.top, AppStyle.defaultPadding)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

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

// Rangée pour les objets fonctionnels (Affiche le niveau/quantité)
struct InventoryRow: View {
    let item: ShopItem
    @ObservedObject var data: GameData
    
    var currentLevel: Int {
        return data.itemLevels[item.name, default: 0]
    }
    
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
            
            // Affichage du statut
            if item.category == .production || item.category == .outil {
                Text("Niv: \(currentLevel)")
                    .fontWeight(.bold)
                    .foregroundColor(AppStyle.accentColor)
            } else if item.category == .amelioration || item.category == .defense || item.category == .jalonNarratif {
                Text("Acheté ✅")
                    .foregroundColor(AppStyle.positiveColor)
            } else if item.category == .perturbateur {
                 Text("DISPONIBLE ⚔️")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(AppStyle.listRowBackground.opacity(0.8))
    }
}

// Rangée pour les cosmétiques (Permet d'activer/désactiver)
struct CosmeticRow: View {
    let item: ShopItem
    @ObservedObject var data: GameData
    @State private var isActive: Bool = true // Placeholder
    
    var body: some View {
        HStack {
            Text(item.emoji).font(.largeTitle)
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.white)
                // CORRECTION : Utilisation de item.category (RawValue est le nom lisible)
                Text(item.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            // Logique d'activation
            Toggle("", isOn: $isActive)
                .labelsHidden()
                .tint(AppStyle.accentColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(AppStyle.listRowBackground.opacity(0.8))
    }
}
