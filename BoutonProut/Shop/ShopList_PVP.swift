import Foundation

let pvpShopItems: [ShopItem] = [
    
    // MARK: - ACTE 2 : L'ADOLESCENCE 😈 (La découverte de la méchanceté)
    // Attaques
    ShopItem(name: "Spray Désodorisant", description: "L'ennemi du prouteur. Divise le PPS par 2 pendant 5 min.",
             baseCost: 2000, currency: .pets, category: .perturbateur, emoji: "🧴",
             effectID: "attack_dps_reduction_50", durationMinutes: 5, isConsumable: true, acte: 2),
    
    ShopItem(name: "Pet Foireux", description: "Humiliation totale. Fait perdre 10% des Haricots possédés.",
             baseCost: 5000, currency: .pets, category: .perturbateur, emoji: "💨",
             effectID: "attack_loss_t1_10", durationMinutes: 1, isConsumable: true, acte: 2),
    
    ShopItem(name: "Boule Puante", description: "Incommode tout l'entourage. Bloque le PPC pendant 2 min.",
             baseCost: 8000, currency: .pets, category: .perturbateur, emoji: "🤢",
             effectID: "attack_block_click", durationMinutes: 2, isConsumable: true, acte: 2),
    
    // Défenses
    ShopItem(name: "Bouchon de Fesses", description: "Contre le Spray Désodorisant.",
             baseCost: 1500, currency: .pets, category: .defense, emoji: "🕳️",
             effectID: "defense_anti_spray", isConsumable: true, acte: 2),
    
    ShopItem(name: "Smecta", description: "Solidifie les ambitions. Contre le Pet Foireux.",
             baseCost: 3000, currency: .pets, category: .defense, emoji: "🍚",
             effectID: "defense_anti_loss", isConsumable: true, acte: 2),
    
    ShopItem(name: "Pince à Linge", description: "Protège le nez. Contre la Boule Puante.",
             baseCost: 4000, currency: .pets, category: .defense, emoji: "🧺",
             effectID: "defense_anti_block", isConsumable: true, acte: 2),


    // MARK: - ACTE 3 : LE LOVEUR ❤️ (Guerres de séduction)
    // Attaques
    ShopItem(name: "Lettre de Rupture", description: "Cœur brisé. Divise le PPS par 4 pendant 10 min.",
             baseCost: 50000, currency: .pets, category: .perturbateur, emoji: "💔",
             effectID: "attack_dps_reduction_75", durationMinutes: 10, isConsumable: true, acte: 3),
    
    ShopItem(name: "Voleur de Bague", description: "Sabotage romantique. Vole 20% des bagues possédées.",
             baseCost: 150000, currency: .pets, category: .perturbateur, emoji: "🥷",
             effectID: "attack_steal_rings", durationMinutes: 1, isConsumable: true, acte: 3),
    
    ShopItem(name: "Haleine d'Ail", description: "Tue l'amour. Divise le PPC par 5 pendant 5 min.",
             baseCost: 100000, currency: .pets, category: .perturbateur, emoji: "🧄",
             effectID: "attack_click_reduction_80", durationMinutes: 5, isConsumable: true, acte: 3),
    
    // Défenses
    ShopItem(name: "Poème de Réconciliation", description: "Contre la Lettre de Rupture.",
             baseCost: 40000, currency: .pets, category: .defense, emoji: "📜",
             effectID: "defense_anti_breakup", isConsumable: true, acte: 3),
    
    ShopItem(name: "Coffre-Fort Rose", description: "Protège vos bijoux. Contre le Voleur de Bague.",
             baseCost: 100000, currency: .pets, category: .defense, emoji: "🔐",
             effectID: "defense_anti_theft", isConsumable: true, acte: 3),
    
    ShopItem(name: "Chewing-gum Mentholé", description: "Fraîcheur extrême. Contre l'Haleine d'Ail.",
             baseCost: 80000, currency: .pets, category: .defense, emoji: "🍬",
             effectID: "defense_anti_garlic", isConsumable: true, acte: 3),


    // MARK: - ACTE 4 : MONSIEUR PRO 💼 (Espionnage et Sabotage)
    // Attaques
    ShopItem(name: "Audit Fiscal", description: "Gel des avoirs. Bloque toute production pendant 3 min.",
             baseCost: 5000000, currency: .pets, category: .perturbateur, emoji: "🧐",
             effectID: "attack_freeze_production", durationMinutes: 3, isConsumable: true, acte: 4),
    
    ShopItem(name: "Burn-out", description: "Fatigue intense. Divise tout (PPS/PPC) par 10 pendant 15 min.",
             baseCost: 15000000, currency: .pets, category: .perturbateur, emoji: "😫",
             effectID: "attack_mega_nerf", durationMinutes: 15, isConsumable: true, acte: 4),
    
    ShopItem(name: "Piratage Data Center", description: "Vole 5% du score total instantanément.",
             baseCost: 50000000, currency: .pets, category: .perturbateur, emoji: "💻",
             effectID: "attack_score_steal_5", durationMinutes: 1, isConsumable: true, acte: 4),
    
    // Défenses
    ShopItem(name: "Paradis Fiscal", description: "Contre l'Audit Fiscal.",
             baseCost: 4000000, currency: .pets, category: .defense, emoji: "🏝️",
             effectID: "defense_anti_audit", isConsumable: true, acte: 4),
    
    ShopItem(name: "Pause Café Infinie", description: "Redonne de l'énergie. Contre le Burn-out.",
             baseCost: 10000000, currency: .pets, category: .defense, emoji: "☕",
             effectID: "defense_anti_burnout", isConsumable: true, acte: 4),
    
    ShopItem(name: "Pare-feu de Platine", description: "Sécurité maximale. Contre le Piratage.",
             baseCost: 40000000, currency: .pets, category: .defense, emoji: "🛡️",
             effectID: "defense_anti_hack", isConsumable: true, acte: 4),


    // MARK: - ACTE 5 : LA RETRAITE 👴 (Guerre d'héritage)
    // Attaques
    ShopItem(name: "Dénonciation Syndicale", description: "Bloque le bouton Prout pendant 5 min.",
             baseCost: 500000000, currency: .pets, category: .perturbateur, emoji: "📢",
             effectID: "attack_total_block", durationMinutes: 5, isConsumable: true, acte: 5),
    
    ShopItem(name: "Suppression d'Héritage", description: "Retire tous les bonus d'amélioration pendant 20 min.",
             baseCost: 2000000000, currency: .pets, category: .perturbateur, emoji: "📝",
             effectID: "attack_strip_upgrades", durationMinutes: 20, isConsumable: true, acte: 5),
    
    ShopItem(name: "Vol de Dentier", description: "Impossible de manger des haricots. PPS réduit de 90%.",
             baseCost: 10000000000, currency: .pets, category: .perturbateur, emoji: "🦷",
             effectID: "attack_extreme_dps_nerf", durationMinutes: 10, isConsumable: true, acte: 5),
    
    // Défenses
    ShopItem(name: "Appel au Petit-Fils", description: "Le support technique familial. Contre la Dénonciation.",
             baseCost: 400000000, currency: .pets, category: .defense, emoji: "🤳",
             effectID: "defense_anti_block_total", isConsumable: true, acte: 5),
    
    ShopItem(name: "Notaire Véreux", description: "Protège votre testament. Contre la Suppression d'Héritage.",
             baseCost: 1500000000, currency: .pets, category: .defense, emoji: "⚖️",
             effectID: "defense_anti_legacy", isConsumable: true, acte: 5),
    
    ShopItem(name: "Colle Fixodent", description: "Le dentier ne bouge plus. Contre le Vol de Dentier.",
             baseCost: 8000000000, currency: .pets, category: .defense, emoji: "🧪",
             effectID: "defense_anti_teeth_theft", isConsumable: true, acte: 5)
]
