import Foundation

let standardShopItems: [ShopItem] = [
    
    // MARK: - ACTE 1 : BÉBÉ MERDE 👶 (Prix : 10 à 5 000)
    // Outils (PPC)
    ShopItem(name: "Doigt de Bébé", description: "+1 PPC.", baseCost: 15, currency: .pets, category: .outil, emoji: "👉", clickMultiplier: 1, acte: 1),
    ShopItem(name: "Tétine Usée", description: "+2 PPC.", baseCost: 80, currency: .pets, category: .outil, emoji: "🍼", clickMultiplier: 2, acte: 1),
    ShopItem(name: "Hochet Bruyant", description: "+5 PPC.", baseCost: 300, currency: .pets, category: .outil, emoji: "🪇", clickMultiplier: 5, acte: 1),
    ShopItem(name: "Cuillère en Plastique", description: "+10 PPC.", baseCost: 800, currency: .pets, category: .outil, emoji: "🥄", clickMultiplier: 10, acte: 1),
    ShopItem(name: "Petit Pot de Purée", description: "+25 PPC.", baseCost: 2500, currency: .pets, category: .outil, emoji: "🥣", clickMultiplier: 25, acte: 1),
    // Bâtiments (PPS)
    ShopItem(name: "Haricot Unique", description: "1 pet / 10s.", baseCost: 50, currency: .pets, category: .production, emoji: "🫘", dpsRate: 1.0, acte: 1),
    ShopItem(name: "Tonton Blagueur", description: "4 pets / 10s.", baseCost: 250, currency: .pets, category: .production, emoji: "🤡", dpsRate: 4.0, acte: 1),
    ShopItem(name: "Poussette à Vapeur", description: "12 pets / 10s.", baseCost: 1200, currency: .pets, category: .production, emoji: "🛒", dpsRate: 12.0, acte: 1),
    ShopItem(name: "Bain à Bulles", description: "30 pets / 10s.", baseCost: 4500, currency: .pets, category: .production, emoji: "🧼", dpsRate: 30.0, acte: 1),
    ShopItem(name: "Couche Full-Option", description: "75 pets / 10s.", baseCost: 12000, currency: .pets, category: .production, emoji: "🧷", dpsRate: 75.0, acte: 1),
    // Améliorations
    ShopItem(name: "Purée de Brocolis", description: "Haricot x2.", baseCost: 500, currency: .pets, category: .amelioration, emoji: "🥦", requiredItem: "Haricot Unique", requiredItemCount: 10, acte: 1),
    ShopItem(name: "Blague Carambar", description: "Tonton x2.", baseCost: 1500, currency: .pets, category: .amelioration, emoji: "🍬", requiredItem: "Tonton Blagueur", requiredItemCount: 10, acte: 1),
    ShopItem(name: "Double Doigt", description: "Doigt de Bébé x2.", baseCost: 1000, currency: .pets, category: .amelioration, emoji: "✌️", requiredItem: "Doigt de Bébé", requiredItemCount: 15, acte: 1),
    ShopItem(name: "Savon Magique", description: "Bain à Bulles x2.", baseCost: 6000, currency: .pets, category: .amelioration, emoji: "🫧", requiredItem: "Bain à Bulles", requiredItemCount: 5, acte: 1),
    ShopItem(name: "Turbo Couche", description: "PPS Global +5%.", baseCost: 10000, currency: .pets, category: .amelioration, emoji: "⚡", acte: 1),
    // Jalons
    ShopItem(name: "Apprendre à Marcher", description: "Fini de ramper.", baseCost: 3000, currency: .pets, category: .jalonNarratif, emoji: "🚶", acte: 1),
    ShopItem(name: "Dire son premier mot", description: "Prépare l'Acte 2.", baseCost: 8000, currency: .pets, category: .jalonNarratif, emoji: "🗣️", acte: 1),

    // MARK: - ACTE 2 : L'ADOLESCENCE 😈 (Prix : 15 000 à 200 000)
    // Outils
    ShopItem(name: "Crayon de Collégien", description: "+60 PPC.", baseCost: 15000, currency: .pets, category: .outil, emoji: "✏️", clickMultiplier: 60, acte: 2),
    ShopItem(name: "Manette de Jeu", description: "+150 PPC.", baseCost: 40000, currency: .pets, category: .outil, emoji: "🎮", clickMultiplier: 150, acte: 2),
    ShopItem(name: "Skateboard Cassé", description: "+350 PPC.", baseCost: 85000, currency: .pets, category: .outil, emoji: "🛹", clickMultiplier: 350, acte: 2),
    ShopItem(name: "Smartphone Écran Brisé", description: "+800 PPC.", baseCost: 150000, currency: .pets, category: .outil, emoji: "📱", clickMultiplier: 800, acte: 2),
    ShopItem(name: "Guitare Électrique", description: "+2000 PPC.", baseCost: 400000, currency: .pets, category: .outil, emoji: "🎸", clickMultiplier: 2000, acte: 2),
    // Bâtiments
    ShopItem(name: "Cantine Scolaire", description: "180 pets / 10s.", baseCost: 25000, currency: .pets, category: .production, emoji: "🍱", dpsRate: 180.0, acte: 2),
    ShopItem(name: "Bus de Nuit", description: "450 pets / 10s.", baseCost: 65000, currency: .pets, category: .production, emoji: "🚌", dpsRate: 450.0, acte: 2),
    ShopItem(name: "Vache de Ferme", description: "1200 pets / 10s.", baseCost: 180000, currency: .pets, category: .production, emoji: "🐄", dpsRate: 1200.0, acte: 2),
    ShopItem(name: "Kebab de minuit", description: "3500 pets / 10s.", baseCost: 450000, currency: .pets, category: .production, emoji: "🥙", dpsRate: 3500.0, acte: 2),
    ShopItem(name: "Salle de Muscu", description: "9000 pets / 10s.", baseCost: 1200000, currency: .pets, category: .production, emoji: "🏋️", dpsRate: 9000.0, acte: 2),
    // Améliorations
    ShopItem(name: "Sauce Samouraï", description: "Kebab x2.", baseCost: 200000, currency: .pets, category: .amelioration, emoji: "🔥", requiredItem: "Kebab de minuit", requiredItemCount: 10, acte: 2),
    ShopItem(name: "Wifi 5G", description: "Smartphone x3.", baseCost: 150000, currency: .pets, category: .amelioration, emoji: "📶", requiredItem: "Smartphone Écran Brisé", requiredItemCount: 5, acte: 2),
    ShopItem(name: "Blague de Vestiaire", description: "PPS Global +10%.", baseCost: 300000, currency: .pets, category: .amelioration, emoji: "👕", acte: 2),
    ShopItem(name: "Protéines en Poudre", description: "Muscu x2.", baseCost: 500000, currency: .pets, category: .amelioration, emoji: "🥛", requiredItem: "Salle de Muscu", requiredItemCount: 10, acte: 2),
    ShopItem(name: "Combo Manette", description: "PPC x2.", baseCost: 250000, currency: .pets, category: .amelioration, emoji: "🕹️", acte: 2),
    // Jalons
    ShopItem(name: "Découvrir la Méchanceté", description: "Débloque le PvP.", baseCost: 50000, currency: .pets, category: .jalonNarratif, emoji: "😈", effectID: "unlock_combat", acte: 2),
    ShopItem(name: "Passe le Bac", description: "Liberté ! Vers l'Acte 3.", baseCost: 500000, currency: .pets, category: .jalonNarratif, emoji: "🎓", acte: 2),

    // MARK: - ACTE 3 : L'AMOUR ❤️ (Prix : 1M à 15M)
    // Outils
    ShopItem(name: "Bouquet de Roses", description: "+5k PPC.", baseCost: 1000000, currency: .pets, category: .outil, emoji: "🌹", clickMultiplier: 5000, acte: 3),
    ShopItem(name: "Bague en Toc", description: "+12k PPC.", baseCost: 2500000, currency: .pets, category: .outil, emoji: "💍", clickMultiplier: 12000, acte: 3),
    ShopItem(name: "Poème Mal Écrit", description: "+30k PPC.", baseCost: 6000000, currency: .pets, category: .outil, emoji: "📝", clickMultiplier: 30000, acte: 3),
    ShopItem(name: "Boîte de Chocolats", description: "+75k PPC.", baseCost: 15000000, currency: .pets, category: .outil, emoji: "🍫", clickMultiplier: 75000, acte: 3),
    ShopItem(name: "Sérénade au Balcon", description: "+200k PPC.", baseCost: 40000000, currency: .pets, category: .outil, emoji: "🎻", clickMultiplier: 200000, acte: 3),
    // Bâtiments
    ShopItem(name: "Cinéma Romantique", description: "25k pets / 10s.", baseCost: 2000000, currency: .pets, category: .production, emoji: "🎬", dpsRate: 25000.0, acte: 3),
    ShopItem(name: "Restaurant Italien", description: "70k pets / 10s.", baseCost: 5500000, currency: .pets, category: .production, emoji: "🍝", dpsRate: 70000.0, acte: 3),
    ShopItem(name: "Parc aux Cygnes", description: "180k pets / 10s.", baseCost: 14000000, currency: .pets, category: .production, emoji: "🦢", dpsRate: 180000.0, acte: 3),
    ShopItem(name: "Mariage à Vegas", description: "500k pets / 10s.", baseCost: 40000000, currency: .pets, category: .production, emoji: "💒", dpsRate: 500000.0, acte: 3),
    ShopItem(name: "Villa des Amoureux", description: "1.2M pets / 10s.", baseCost: 100000000, currency: .pets, category: .production, emoji: "🏡", dpsRate: 1200000.0, acte: 3),
    // Améliorations
    ShopItem(name: "Chandelles Parfumées", description: "Resto x2.", baseCost: 5000000, currency: .pets, category: .amelioration, emoji: "🕯️", requiredItem: "Restaurant Italien", requiredItemCount: 10, acte: 3),
    ShopItem(name: "Violoniste Privé", description: "Sérénade x3.", baseCost: 12000000, currency: .pets, category: .amelioration, emoji: "🎻", requiredItem: "Sérénade au Balcon", requiredItemCount: 5, acte: 3),
    ShopItem(name: "Coup de Foudre", description: "PPS Global +15%.", baseCost: 25000000, currency: .pets, category: .amelioration, emoji: "⚡", acte: 3),
    ShopItem(name: "Lune de Miel", description: "Mariage x2.", baseCost: 50000000, currency: .pets, category: .amelioration, emoji: "✈️", requiredItem: "Mariage à Vegas", requiredItemCount: 1, acte: 3),
    ShopItem(name: "Amour Toujours", description: "PPC x2.", baseCost: 35000000, currency: .pets, category: .amelioration, emoji: "💖", acte: 3),
    // Jalons
    ShopItem(name: "Trouver l'âme soeur", description: "Vous n'êtes plus seul.", baseCost: 8000000, currency: .pets, category: .jalonNarratif, emoji: "👩‍❤️‍👨", acte: 3),
    ShopItem(name: "Fonder un Foyer", description: "Vers les responsabilités (Acte 4).", baseCost: 50000000, currency: .pets, category: .jalonNarratif, emoji: "🏠", acte: 3),

    // MARK: - ACTE 4 : MONSIEUR PRO 💼 (Prix : 60M à 800M)
    // Outils
    ShopItem(name: "Café de Bureau", description: "+500k PPC.", baseCost: 150000000, currency: .pets, category: .outil, emoji: "☕", clickMultiplier: 500000, acte: 4),
    ShopItem(name: "Badge de Sécurité", description: "+1.2M PPC.", baseCost: 400000000, currency: .pets, category: .outil, emoji: "🪪", clickMultiplier: 1200000, acte: 4),
    ShopItem(name: "Clavier Mécanique", description: "+3M PPC.", baseCost: 1000000000, currency: .pets, category: .outil, emoji: "⌨️", clickMultiplier: 3000000, acte: 4),
    ShopItem(name: "Fauteuil de PDG", description: "+8M PPC.", baseCost: 3000000000, currency: .pets, category: .outil, emoji: "💺", clickMultiplier: 8000000, acte: 4),
    ShopItem(name: "Tampon de Validation", description: "+25M PPC.", baseCost: 10000000000, currency: .pets, category: .outil, emoji: "Stamp", clickMultiplier: 25000000, acte: 4),
    // Bâtiments
    ShopItem(name: "Open Space", description: "4M pets / 10s.", baseCost: 250000000, currency: .pets, category: .production, emoji: "🏢", dpsRate: 4000000.0, acte: 4),
    ShopItem(name: "Usine de Haricot XXL", description: "12M pets / 10s.", baseCost: 800000000, currency: .pets, category: .production, emoji: "🏭", dpsRate: 12000000.0, acte: 4),
    ShopItem(name: "Data Center", description: "45M pets / 10s.", baseCost: 3000000000, currency: .pets, category: .production, emoji: "🖥️", dpsRate: 45000000.0, acte: 4),
    ShopItem(name: "Bourse Mondiale", description: "150M pets / 10s.", baseCost: 12000000000, currency: .pets, category: .production, emoji: "📈", dpsRate: 150000000.0, acte: 4),
    ShopItem(name: "Trou Noir Industriel", description: "500M pets / 10s.", baseCost: 50000000000, currency: .pets, category: .production, emoji: "🕳️", dpsRate: 500000000.0, acte: 4),
    // Améliorations
    ShopItem(name: "Intelligence Artificielle", description: "Data Center x2.", baseCost: 2000000000, currency: .pets, category: .amelioration, emoji: "🤖", requiredItem: "Data Center", requiredItemCount: 10, acte: 4),
    ShopItem(name: "Optimisation Fiscale", description: "Bourse x2.", baseCost: 5000000000, currency: .pets, category: .amelioration, emoji: "💸", requiredItem: "Bourse Mondiale", requiredItemCount: 5, acte: 4),
    ShopItem(name: "Caféine Pure", description: "PPC x3.", baseCost: 3000000000, currency: .pets, category: .amelioration, emoji: "🧪", requiredItem: "Café de Bureau", requiredItemCount: 50, acte: 4),
    ShopItem(name: "Synergie de Groupe", description: "PPS Global +20%.", baseCost: 10000000000, currency: .pets, category: .amelioration, emoji: "🤝", acte: 4),
    ShopItem(name: "Climatisation Centrale", description: "Open Space x2.", baseCost: 4000000000, currency: .pets, category: .amelioration, emoji: "❄️", requiredItem: "Open Space", requiredItemCount: 20, acte: 4),
    // Jalons
    ShopItem(name: "Devenir Patron", description: "Vous contrôlez le marché.", baseCost: 1000000000, currency: .pets, category: .jalonNarratif, emoji: "🕴️", acte: 4),
    ShopItem(name: "Faire Fortune", description: "Prêt pour la retraite (Acte 5).", baseCost: 25000000000, currency: .pets, category: .jalonNarratif, emoji: "💰", acte: 4),

    // MARK: - ACTE 5 : LA RETRAITE 👴 (Prix : 50 Milliards+)
    // Outils
    ShopItem(name: "Canne en Chêne", description: "+100M PPC.", baseCost: 100000000000, currency: .pets, category: .outil, emoji: "🦯", clickMultiplier: 100000000, acte: 5),
    ShopItem(name: "Télécommande", description: "+300M PPC.", baseCost: 350000000000, currency: .pets, category: .outil, emoji: "📺", clickMultiplier: 300000000, acte: 5),
    ShopItem(name: "Paire de Lunettes", description: "+1B PPC.", baseCost: 1000000000000, currency: .pets, category: .outil, emoji: "👓", clickMultiplier: 1000000000, acte: 5),
    ShopItem(name: "Appareil Auditif", description: "+5B PPC.", baseCost: 5000000000000, currency: .pets, category: .outil, emoji: "🦻", clickMultiplier: 5000000000, acte: 5),
    ShopItem(name: "Le Dentier d'Or", description: "+25B PPC.", baseCost: 20000000000000, currency: .pets, category: .outil, emoji: "🦷", clickMultiplier: 25000000000, acte: 5),
    // Bâtiments
    ShopItem(name: "Banc du Parc", description: "2B pets / 10s.", baseCost: 150000000000, currency: .pets, category: .production, emoji: "🪵", dpsRate: 2000000000.0, acte: 5),
    ShopItem(name: "Club de Bridge", description: "8B pets / 10s.", baseCost: 600000000000, currency: .pets, category: .production, emoji: "🃏", dpsRate: 8000000000.0, acte: 5),
    ShopItem(name: "Croisière Senior", description: "25B pets / 10s.", baseCost: 2000000000000, currency: .pets, category: .production, emoji: "🚢", dpsRate: 25000000000.0, acte: 5),
    ShopItem(name: "Maison de Retraite VIP", description: "100B pets / 10s.", baseCost: 10000000000000, currency: .pets, category: .production, emoji: "🏩", dpsRate: 100000000000.0, acte: 5),
    ShopItem(name: "Big Bang Final", description: "500B pets / 10s.", baseCost: 60000000000000, currency: .pets, category: .production, emoji: "💥", dpsRate: 500000000000.0, acte: 5),
    // Améliorations
    ShopItem(name: "Sieste l'après-midi", description: "PPS Global +30%.", baseCost: 1000000000000, currency: .pets, category: .amelioration, emoji: "😴", acte: 5),
    ShopItem(name: "Infirmière de Garde", description: "Maison VIP x2.", baseCost: 5000000000000, currency: .pets, category: .amelioration, emoji: "👩‍⚕️", requiredItem: "Maison de Retraite VIP", requiredItemCount: 1, acte: 5),
    ShopItem(name: "Chocolat Chaud", description: "PPC x5.", baseCost: 2000000000000, currency: .pets, category: .amelioration, emoji: "☕", acte: 5),
    ShopItem(name: "Sagesse Infinie", description: "PPS Global +50%.", baseCost: 50000000000000, currency: .pets, category: .amelioration, emoji: "🧠", acte: 5),
    ShopItem(name: "Dentier vibrant", description: "Bridge x4.", baseCost: 2000000000000, currency: .pets, category: .amelioration, emoji: "🦷", requiredItem: "Club de Bridge", requiredItemCount: 10, acte: 5),
    // Jalons
    ShopItem(name: "Écrire ses mémoires", description: "Prêt à partir.", baseCost: 10000000000000, currency: .pets, category: .jalonNarratif, emoji: "📖", acte: 5),
    ShopItem(name: "Le Grand Reset", description: "Fin du cycle. Prestige.", baseCost: 100000000000000, currency: .pets, category: .jalonNarratif, emoji: "🔄", effectID: "unlock_prestige", acte: 5)
]
