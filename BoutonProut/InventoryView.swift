import SwiftUI

// MARK: - VUE INVENTAIRE
// Cette vue regroupe les objets possédés par le joueur, classés par Acte (âge).
struct InventoryView: View {
    @ObservedObject var data: GameData
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab: InventoryCategory = .functional
    
    enum InventoryCategory: String {
        case functional = "Ma Progression"
        case cosmetics = "Mon Style"
    }
    
    // Filtre les objets possédés fonctionnels (Hors Combat)
    var ownedFunctionalItems: [ShopItem] {
        return data.allItems.filter { item in
            let isFunctional = (
                item.category == .production ||
                item.category == .amelioration ||
                item.category == .outil ||
                item.category == .jalonNarratif
            )
            // On vérifie que l'item est possédé ET qu'il fait partie des catégories ci-dessus
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
                // Barre de titre personnalisée
                CustomTitleBar(title: "Mes Objets 🗃️", onDismiss: { dismiss() })
                
                // Sélecteur d'onglet (Progression vs Cosmétiques)
                Picker("Type d'Inventaire", selection: $selectedTab) {
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
                                // On boucle sur les 5 actes pour organiser l'inventaire par "âge"
                                ForEach(1...5, id: \.self) { acteNum in
                                    let itemsInActe = ownedFunctionalItems.filter { $0.acte == acteNum }
                                    
                                    // On n'affiche la section que si le joueur possède des objets de cet acte
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
                            
                        } else if selectedTab == .cosmetics {
                            // Affichage des cosmétiques possédés
                            if !ownedCosmeticItems.isEmpty {
                                InventorySection(title: "Apparence & Sons") {
                                    ForEach(ownedCosmeticItems, id: \.name) { item in
                                        CosmeticRow(item: item, data: data)
                                    }
                                }
                            } else {
                                Text("Aucun cosmétique débloqué.")
                                    .inventoryEmptyText()
                            }
                        }
                    }
                    .padding(AppStyle.defaultPadding)
                }
            }
        }
    }
    
    // Helper pour transformer le numéro d'acte en nom narratif
    func acteTitle(for acte: Int) -> String {
        switch acte {
            case 1: return "Acte I : Bébé Merde 👶"
            case 2: return "Acte II : L'Âge Ingrat 😈"
            case 3: return "Acte III : Le Loveur ❤️"
            case 4: return "Acte IV : Monsieur Pro 💼"
            case 5: return "Acte V : La Retraite 👴"
            default: return "Acte Inconnu"
        }
    }
}

// MARK: - STRUCTURES D'AIDE

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
            
            // Affichage du statut simplifié
            if item.category == .production || item.category == .outil {
                Text("Lv. \(data.itemLevels[item.name, default: 0])")
                    .fontWeight(.bold)
                    .foregroundColor(AppStyle.accentColor)
            } else {
                Text("Acquis ✅")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(12)
        .background(AppStyle.listRowBackground)
    }
}

struct CosmeticRow: View {
    let item: ShopItem
    @ObservedObject var data: GameData
    @State private var isActive: Bool = true // Ici tu pourras lier à la logique de skin de GameData
    
    var body: some View {
        HStack {
            Text(item.emoji).font(.largeTitle)
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(item.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Toggle("", isOn: $isActive)
                .labelsHidden()
                .tint(AppStyle.accentColor)
        }
        .padding(12)
        .background(AppStyle.listRowBackground)
    }
}

// Helper pour le style des messages vides
extension View {
    func inventoryEmptyText() -> some View {
        self
        .foregroundColor(AppStyle.secondaryTextColor)
        .padding(.top, 40)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
