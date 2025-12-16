import Foundation

// NOTE : Nécessite ShopModels.swift pour les structures ShopItem et CurrencyType
// Prix ajustés pour le PQ d'Or (beaucoup plus bas que les pets)

let cosmeticShopItems: [ShopItem] = [
    
    // --- SKINS CACA (Monnaie: PQ d'Or) ---
    ShopItem(name: "Caca Doré", description: "Faites la fierté de vos pets. Change l'emoji central.", baseCost: 10, currency: .goldenPaper, category: .skin, emoji: "🌟", cosmeticID: "golden_poop"),
    ShopItem(name: "Caca Galactique", description: "Le prout des étoiles.", baseCost: 25, currency: .goldenPaper, category: .skin, emoji: "🪐", cosmeticID: "galactic_poop"),
    ShopItem(name: "Caca Pixel", description: "L'ère des 8 bits.", baseCost: 5, currency: .goldenPaper, category: .skin, emoji: "🧱", cosmeticID: "pixel_poop"),
    
    // --- SONS (Monnaie: PQ d'Or) ---
    ShopItem(name: "Sons Cartoon", description: "Des bruits plus amusants (Pouet !).", baseCost: 5, currency: .goldenPaper, category: .sound, emoji: "🔊", cosmeticID: "cartoon_sound_pack"),
    ShopItem(name: "Sons Métal", description: "Bruits de cloches et de tonnerre.", baseCost: 15, currency: .goldenPaper, category: .sound, emoji: "🤘", cosmeticID: "metal_sounds"),
    
    // --- FONDS D'ÉCRAN (Monnaie: PQ d'Or) ---
    ShopItem(name: "Fond Nuit Pastel", description: "Change le fond d'écran de l'application.", baseCost: 3, currency: .goldenPaper, category: .background, emoji: "🌃", cosmeticID: "pastel_bg"),
    ShopItem(name: "Fond Forêt", description: "Ambiance jungle humide.", baseCost: 8, currency: .goldenPaper, category: .background, emoji: "🌳", cosmeticID: "forest_bg"),

    // --- MUSIQUE (Monnaie: PQ d'Or) ---
    ShopItem(name: "Jazz Fart", description: "Musique d'ambiance relaxante et prout discret en boucle.", baseCost: 20, currency: .goldenPaper, category: .music, emoji: "🎷", cosmeticID: "jazz_fart_music"),
]
