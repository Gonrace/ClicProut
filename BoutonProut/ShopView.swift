import SwiftUI

// NOTE: Assurez-vous que les fichiers ShopModels.swift, ShopList_Standard.swift,
//       ShopList_Cosmetics.swift et StyleConstants.swift sont dans votre projet.

struct ShopView: View {
    
    @ObservedObject var data: GameData
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab: ShopCategory = .tools
    
    enum ShopCategory: String {
        case tools = "Production & Logique" // Nouveau nom plus large
        case cosmetics = "Cosmétiques"
        case currency = "Acheter PQ d'Or"
    }
    
    var body: some View {
        ZStack {
            AppStyle.secondaryBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 1. BARRE DE TITRE
                CustomTitleBar(title: "La Proutique 🛍️", onDismiss: { dismiss() })
                
                // Affichage du score (Double Monnaie)
                HStack(spacing: 20) {
                    Text("Pets : \(data.totalFartCount) 💩")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("PQ d'Or : \(data.goldenToiletPaper) 👑")
                        .font(.headline)
                        .foregroundColor(AppStyle.accentColor)
                }
                .padding(.bottom, AppStyle.defaultPadding)
                
                // 2. SEGMENT DE SÉLECTION (3 CATÉGORIES)
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
                            
                            // 1. --- OUTILS DE CLIC ---
                            ShopSection(title: "1. Outils de Clic (Manuel - PPC)") {
                                ForEach(standardShopItems.filter { $0.category == .outil }, id: \.id) { item in
                                    ItemRow(item: item, data: data)
                                }
                            }
                            
                            // 2. --- BÂTIMENTS ---
                            ShopSection(title: "2. Bâtiments (Automatique - PPS)") {
                                ForEach(standardShopItems.filter { $0.category == .production }, id: \.id) { item in
                                    ItemRow(item: item, data: data)
                                }
                            }
                            
                            // 3. --- AMÉLIORATIONS ---
                            ShopUniqueSection(
                                data: data,
                                title: "3. Améliorations (Bonus Permanent)",
                                category: .amelioration
                            )

                            // 4. --- DÉFENSE ---
                            ShopUniqueSection(
                                data: data,
                                title: "4. Défense (Protection Passive)",
                                category: .defense
                            )

                            // 5. --- ATTAQUE / PERTURBATEUR ---
                            ShopUniqueSection(
                                data: data,
                                title: "5. Attaque / Perturbateur (PvP)",
                                category: .perturbateur
                            )

                            // 6. --- JALON NARRATIF ---
                            ShopUniqueSection(
                                data: data,
                                title: "6. Jalons Narratifs (Progression)",
                                category: .jalonNarratif
                            )

                        } else if selectedTab == .cosmetics {
                            // --- COSMÉTIQUES & Perturbateurs PQ d'Or ---
                            ShopCosmeticsSection(data: data)
                            
                        } else { // selectedTab == .currency
                            IAPShopView(data: data)
                        }
                    }
                    .padding(.horizontal, AppStyle.defaultPadding)
                    .padding(.bottom, 50)
                }
            }
        }
    }
    
    // --- STRUCTURES D'AIDE UNIQUES ---
    
    // Rangée pour les achats uniques déjà complétés
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
                Text("ACHETÉ ✅").foregroundColor(AppStyle.positiveColor).font(.caption)
            }
            .padding(8)
            .background(AppStyle.listRowBackground)
            .cornerRadius(10)
        }
    }

    // Vue générique pour regrouper les Achats Uniques (Amélioration, Défense, etc.)
    struct ShopUniqueSection: View {
        @ObservedObject var data: GameData
        let title: String
        let category: ItemCategory
        
        var body: some View {
            let uniqueItems = standardShopItems.filter { $0.category == category }
            
            if !uniqueItems.isEmpty {
                ShopSection(title: title) {
                    ForEach(uniqueItems, id: \.id) { item in
                        // Si déjà acheté et non consommable, afficher "ACHETÉ"
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

    // Section pour Cosmétiques et Perturbateurs en PQ d'Or (S'il y en a)
    struct ShopCosmeticsSection: View {
        @ObservedObject var data: GameData
        
        var perturbateursPQ: [ShopItem] {
            return standardShopItems.filter { $0.category == .perturbateur && $0.currency == .goldenPaper }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: AppStyle.defaultPadding) {
                
                if !perturbateursPQ.isEmpty {
                     ShopSection(title: "Armes Premium (PvP en 👑)") {
                         ForEach(perturbateursPQ, id: \.id) { item in
                            ItemRow(item: item, data: data)
                         }
                     }
                }

                if !cosmeticShopItems.isEmpty {
                    ShopSection(title: "Personnalisation") {
                        ForEach(cosmeticShopItems, id: \.id) { item in
                            ItemRow(item: item, data: data)
                        }
                    }
                }
            }
        }
    }


    // --- STRUCTURES D'AIDE GÉNÉRALES ---
    
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

    struct ItemRow: View {
        let item: ShopItem
        @ObservedObject var data: GameData
        
        var currentLevel: Int {
            return data.itemLevels[item.name, default: 0]
        }
        
        // Calcule le coût à afficher
        var displayCost: Int {
            let level = data.itemLevels[item.name, default: 0]
            // Coût fixe pour tous les achats uniques, progressif pour Production/Outil
            if item.category != .production && item.category != .outil {
                return item.baseCost
            } else {
                let cost = Double(item.baseCost) * pow(1.2, Double(level))
                return Int(cost.rounded())
            }
        }

        // Détermine si l'achat est possible (utilise la logique de GameData)
        var canAffordAndAvailable: Bool {
                    
            // CORRECTION DU BUG 1: Appliquer la même logique de vérification d'unicité que dans GameData
            let isUniqueCategory = (item.category == .amelioration || item.category == .defense || item.category == .jalonNarratif || item.category == .perturbateur || item.category == .skin || item.category == .sound || item.category == .background || item.category == .music)

            // Empêche l'achat si c'est unique et déjà possédé ET NON CONSOMMABLE
            if !item.isConsumable && isUniqueCategory && currentLevel > 0 {
                return false
            }
                
            // Vérification du prérequis (inchangée, elle est OK)
            if let req = item.requiredItem, let reqCount = item.requiredItemCount {
                if data.itemLevels[req, default: 0] < reqCount { return false }
            }
                    
            // Vérification de l'argent (inchangée, elle est OK)
            if item.currency == .pets {
                return data.totalFartCount >= displayCost
            } else { // Golden Paper
                return data.goldenToiletPaper >= displayCost
            }
        }
        func buyItem() {
            let success = data.attemptPurchase(item: item)
            
            if success {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
        
        var body: some View {
            let isInteractable = canAffordAndAvailable
            
            HStack {
                Text(item.emoji).font(.largeTitle)
                
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Description et niveau
                    Text(descriptionText(item: item))
                        .font(.caption)
                        .foregroundColor(item.currency == .goldenPaper ? .cyan : AppStyle.secondaryTextColor)
                    
                    // Message de prérequis (s'il n'est pas rempli)
                    if let req = item.requiredItem, let reqCount = item.requiredItemCount, !isInteractable {
                        if data.itemLevels[req, default: 0] < reqCount {
                            Text("Nécessite \(req) Niv \(reqCount)").font(.caption).foregroundColor(AppStyle.warningColor)
                        }
                    }
                }
                
                Spacer()
                
                // Le bouton d'achat
                Button(action: buyItem) {
                    VStack {
                        Text("\(displayCost)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        // Symbole de la monnaie
                        Text(item.currency.rawValue.split(separator: " ").last?.description ?? "?")
                            .font(.caption)
                            .foregroundColor(item.currency == .goldenPaper ? AppStyle.accentColor : .white)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(isInteractable ? AppStyle.positiveColor : AppStyle.secondaryButtonColor)
                    .cornerRadius(8)
                }
                .disabled(!isInteractable)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(AppStyle.listRowBackground.opacity(0.8))
            .opacity(isInteractable ? 1.0 : 0.6)
        }
        
        // Helper pour afficher le texte de description
        func descriptionText(item: ShopItem) -> String {
            switch item.category {
            case .production:
                return "\(String(format: "%.1f", item.dpsRate / 10.0)) PPS | Niv: \(currentLevel)"
            case .outil:
                return "+\(item.clickMultiplier) Clics | Niv: \(currentLevel)"
            case .amelioration, .defense, .jalonNarratif:
                return item.description
            case .perturbateur:
                return "Attaque PvP - \(item.description)"
            default: // Cosmétique
                return "\(item.category.rawValue) - \(item.description)"
            }
        }
    }

    // --- NOUVELLE VUE : ACHAT DE PQ D'OR (MOCK IAP) ---
    struct IAPShopView: View {
        @ObservedObject var data: GameData
        
        // Définitions mock des packs IAP (Nom, Prix réel, Quantité de PQ d'Or)
        let iapPacks = [
            ("Petit Rouleau", "0.99€", 10),
            ("Pack Confort", "4.99€", 60),
            ("Super Rouleau Famille", "9.99€", 150),
            ("Caisse de Luxe", "19.99€", 350)
        ]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text("Achetez du PQ d'Or 👑")
                    .font(AppStyle.subTitleFont)
                    .foregroundColor(.white)
                
                Text("Le PQ d'Or est la monnaie premium du jeu, utilisée pour acheter des cosmétiques et des armes PvP premium. Il est acquis uniquement via des achats intégrés (In-App Purchases).")
                    .font(.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                // Affichage du solde actuel
                HStack {
                    Text("Votre Solde :").foregroundColor(.white)
                    Text("\(data.goldenToiletPaper) 👑")
                        .fontWeight(.bold)
                        .foregroundColor(AppStyle.accentColor)
                }
                .padding(.bottom, 10)
                
                VStack(spacing: 1) {
                    ForEach(iapPacks, id: \.0) { (name, price, amount) in
                        IAPPackRow(name: name, price: price, amount: amount, data: data)
                    }
                }
                .background(AppStyle.listRowBackground)
                .cornerRadius(10)
            }
            .padding(.vertical, 10)
        }
    }

    // Rangée pour un pack IAP
    struct IAPPackRow: View {
        let name: String
        let price: String
        let amount: Int
        @ObservedObject var data: GameData
        
        var body: some View {
            HStack {
                Image(systemName: "crown.fill").foregroundColor(AppStyle.accentColor)
                VStack(alignment: .leading) {
                    Text(name).font(.headline).foregroundColor(.white)
                    Text("Contient \(amount) 👑").font(.caption).foregroundColor(AppStyle.secondaryTextColor)
                }
                Spacer()
                
                Button(action: {
                    // MOCK IAP: Simule l'achat réussi et ajoute la monnaie
                    data.goldenToiletPaper += amount // Utilisation directe de la variable
                }) {
                    Text(price)
                        .font(.system(size: 14, weight: .bold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(AppStyle.positiveColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(AppStyle.listRowBackground.opacity(0.8))
        }
    }
}
