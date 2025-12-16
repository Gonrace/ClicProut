import Foundation

// NOTE : Nécessite ShopModels.swift

let standardShopItems: [ShopItem] = [

    // =======================================================================
    // --- ACTE I : DÉPART & ÉDUCATION (T1-T2) ---
    // =======================================================================
    
    // PRODUCTION (Bâtiment)
    ShopItem(name: "Haricot", description: "Base de l'automatisation. 1 pet / 10s.", baseCost: 50, currency: .pets, category: .production, emoji: "🫘", dpsRate: 1.0),
    ShopItem(name: "Tonton Blagueur", description: "Le classique. 3 pets / 10s.", baseCost: 200, currency: .pets, category: .production, emoji: "🤡", dpsRate: 3.0),

    // OUTIL (Clic)
    ShopItem(name: "Doigt de Bébé", description: "Le clic de départ. +1 PPC.", baseCost: 30, currency: .pets, category: .outil, emoji: "👉", clickMultiplier: 1),
    ShopItem(name: "Slip Troué", description: "Moins de friction, plus de clics. +2 PPC.", baseCost: 100, currency: .pets, category: .outil, emoji: "🩲", clickMultiplier: 2),

    // AMÉLIORATION (Upgrade)
    ShopItem(name: "Sauce Piquante", description: "Double le PPS des Haricots.", baseCost: 1000, currency: .pets, category: .amelioration, emoji: "🌶️", requiredItem: "Haricot", requiredItemCount: 10, effectID: "upgrade_haricot_x2"),
    
    // DÉFENSE (Base)
    ShopItem(name: "Smecta", description: "Immunité aux événements 'Pet Foireux' aléatoires (PvE).", baseCost: 5000, currency: .pets, category: .defense, emoji: "🍚", requiredItem: "Tonton Blagueur", requiredItemCount: 5, effectID: "defense_pet_foireux"),
    
    // JALON NARRATIF
    ShopItem(name: "Achète un Livre", description: "Lecture fondamentale. Débloque le T2.", baseCost: 500, currency: .pets, category: .jalonNarratif, emoji: "📚"),
    ShopItem(name: "Passe le Bac", description: "Premier diplôme. Débloque le T3.", baseCost: 5000, currency: .pets, category: .jalonNarratif, emoji: "🎓", requiredItem: "Achète un Livre", requiredItemCount: 1),


    // =======================================================================
    // --- ACTE II : CARRIÈRE & LOGEMENT (T3-T4) ---
    // =======================================================================
    
    // PRODUCTION
    ShopItem(name: "Soupe aux Choux", description: "Le remède de grand-mère. 7 pets / 10s.", baseCost: 800, currency: .pets, category: .production, emoji: "🍲", dpsRate: 7.0),
    ShopItem(name: "Vache", description: "Méthane de ferme. 30 pets / 10s.", baseCost: 6000, currency: .pets, category: .production, emoji: "🐄", dpsRate: 30.0),

    // OUTIL
    ShopItem(name: "Coussin Péteur", description: "Améliore le temps de réaction. +18 PPC.", baseCost: 4000, currency: .pets, category: .outil, emoji: "💨", clickMultiplier: 18),
    ShopItem(name: "Doigt Bionique", description: "Précision mécanique. +50 PPC.", baseCost: 30000, currency: .pets, category: .outil, emoji: "🦾", clickMultiplier: 50),

    // AMÉLIORATION
    ShopItem(name: "Blague Beauf", description: "Triple le PPS du Tonton Blagueur.", baseCost: 5000, currency: .pets, category: .amelioration, emoji: "🍻", requiredItem: "Tonton Blagueur", requiredItemCount: 10, effectID: "upgrade_tonton_x3"),
    ShopItem(name: "Double Clic", description: "Double le PPC de tous les Outils T1.", baseCost: 10000, currency: .pets, category: .amelioration, emoji: "🖱️", requiredItem: "Slip Troué", requiredItemCount: 10, effectID: "upgrade_ppc_t1_x2"),
    
    // PERTURBATEUR (PQ d'Or)
    ShopItem(name: "Spray Désodorisant", description: "Réduit le PPS du Cible de 50% pendant 5 min.", baseCost: 10, currency: .pets, category: .perturbateur, emoji: "👃", effectID: "attack_dps_reduction_50", durationMinutes: 5, isConsumable: false),

    // JALON NARRATIF
    ShopItem(name: "Achète un Appart", description: "Premier investissement. Débloque le T4.", baseCost: 250_000, currency: .pets, category: .jalonNarratif, emoji: "🏢", requiredItem: "Passe le Bac", requiredItemCount: 1),
    ShopItem(name: "Devient Chef", description: "Promotion automatique. Débloque le T5.", baseCost: 500_000, currency: .pets, category: .jalonNarratif, emoji: "🧑‍🍳", requiredItem: "Achète un Appart", requiredItemCount: 1),


    // =======================================================================
    // --- ACTE III : AMOUR & FAMILLE (T5-T6) ---
    // =======================================================================
    
    // PRODUCTION
    ShopItem(name: "Usine de Haricot", description: "Production industrielle. 100 pets / 10s.", baseCost: 40_000, currency: .pets, category: .production, emoji: "🏭", dpsRate: 100.0),
    ShopItem(name: "Éléphant", description: "Le gros générateur. 1200 pets / 10s.", baseCost: 750_000, currency: .pets, category: .production, emoji: "🐘", dpsRate: 1200.0),

    // OUTIL
    ShopItem(name: "Main de Vaudou", description: "Clic mystique. +350 PPC.", baseCost: 750_000, currency: .pets, category: .outil, emoji: "🔮", clickMultiplier: 350),

    // AMÉLIORATION
    ShopItem(name: "Tuyauterie XXL", description: "+5% PPS Global.", baseCost: 250_000, currency: .pets, category: .amelioration, emoji: "💧", requiredItem: "Vache", requiredItemCount: 10, effectID: "upgrade_dps_global_5"),
    
    // DÉFENSE
    ShopItem(name: "Bouchon de Fesses", description: "Protège contre le Spray Désodorisant (PvP).", baseCost: 25_000, currency: .pets, category: .defense, emoji: "🕳️", requiredItem: "Soupe aux Choux", requiredItemCount: 10, effectID: "defense_anti_spray"),

    // PERTURBATEUR
    ShopItem(name: "Pet Foireux", description: "Retire 10% des Tiers 1 du Cible aléatoirement.", baseCost: 25, currency: .pets, category: .perturbateur, emoji: "💨", effectID: "attack_loss_t1_10", isConsumable: false),

    // JALON NARRATIF
    ShopItem(name: "Achète une Bague", description: "Un pas vers l'engagement. Débloque le T6.", baseCost: 1_500_000, currency: .pets, category: .jalonNarratif, emoji: "💍", requiredItem: "Devient Chef", requiredItemCount: 1),
    ShopItem(name: "Rencontre sa Merde", description: "Vous n'êtes plus seul. Débloque le T7.", baseCost: 5_000_000, currency: .pets, category: .jalonNarratif, emoji: "❤️", requiredItem: "Achète une Bague", requiredItemCount: 1),
    
    // =======================================================================
    // --- ACTE IV : SUCCÈS & HÉRITAGE (T7+) ---
    // =======================================================================
    
    // PRODUCTION
    ShopItem(name: "Trou Noir", description: "Gaz cosmiques. 20k pets / 10s.", baseCost: 15_000_000, currency: .pets, category: .production, emoji: "⚫", dpsRate: 20000.0),
    ShopItem(name: "Big Bang", description: "L'origine de l'univers. 50k pets / 10s.", baseCost: 40_000_000, currency: .pets, category: .production, emoji: "💥", dpsRate: 50000.0),

    // OUTIL
    ShopItem(name: "Force du Cosmos", description: "Le clic ultime. +600 PPC.", baseCost: 2_000_000, currency: .pets, category: .outil, emoji: "✨", clickMultiplier: 600),

    // AMÉLIORATION
    ShopItem(name: "Climatisation", description: "Stabilisation, +10% PPS Global.", baseCost: 1_000_000, currency: .pets, category: .amelioration, emoji: "❄️", requiredItem: "Usine de Haricot", requiredItemCount: 10, effectID: "upgrade_dps_global_10"),
    ShopItem(name: "Héritage", description: "Tous les Bâtiments T1 sont multipliés par 5.", baseCost: 50_000_000, currency: .pets, category: .amelioration, emoji: "🧬", requiredItem: "A Enfant Merde", requiredItemCount: 1, effectID: "upgrade_t1_x5"),

    // DÉFENSE
    ShopItem(name: "Assurance Mutuelle", description: "Protège contre les vols et pertes soudaines de Pets.", baseCost: 1_000_000, currency: .pets, category: .defense, emoji: "🛡️", requiredItem: "Achète Maison Famille", requiredItemCount: 1, effectID: "defense_anti_steal"),

    // JALON NARRATIF
    ShopItem(name: "Achète Maison Famille", description: "Le foyer idéal. Débloque le T8.", baseCost: 25_000_000, currency: .pets, category: .jalonNarratif, emoji: "🏠", requiredItem: "Rencontre sa Merde", requiredItemCount: 1),
    ShopItem(name: "A Enfant Merde", description: "L'héritier du royaume. Débloque le T9.", baseCost: 50_000_000, currency: .pets, category: .jalonNarratif, emoji: "👶", requiredItem: "Achète Maison Famille", requiredItemCount: 1),
    ShopItem(name: "Le Grand Reset", description: "Débloque le mode Prestige (Fin du cycle).", baseCost: 100_000_000, currency: .pets, category: .jalonNarratif, emoji: "🔄", requiredItem: "A Enfant Merde", requiredItemCount: 1, effectID: "unlock_prestige"),
]
