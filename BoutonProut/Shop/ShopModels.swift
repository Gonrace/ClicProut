import Foundation

// Type de monnaie
enum CurrencyType: String, Codable {
    case pets = "Pets 💩"
    case goldenPaper = "PQ d'Or 👑"
}

// Catégorie de l'objet (ADAPTATION DES ANCIENS NOMS)
enum ItemCategory: String, Codable {
    case production = "Bâtiment de Pet"       // Auto PPS (Ancien .building)
    case outil = "Outil de Clic"              // Manuel PPC (Ancien .clicker)
    case amelioration = "Amélioration"        // Multiplicateurs (Ancien .upgrade)
    case jalonNarratif = "Jalon Narratif"     // NOUVEAU : Histoire (Ancien .narratif)
    
    //Attaque/Defense
    case defense      = "Défense"
    case perturbateur = "Attaque"
    
    // Cosmétiques
    case skin = "Skin"
    case sound = "Pack Son"
    case background = "Fond d'écran"
    case music = "Musique"
}

// Structure unique de l'objet (MISE À JOUR)
struct ShopItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    let description: String
    let baseCost: Int
    let currency: CurrencyType
    
    let category: ItemCategory
    let emoji: String
    
    // Stats de jeu (Optionnel, 0 par défaut)
    var dpsRate: Double = 0.0
    var clickMultiplier: Int = 0
    
    // Logique de Progression / Attaque / Défense
    var requiredItem: String? = nil
    var requiredItemCount: Int? = nil
    var cosmeticID: String? = nil
    
    // Propriétés pour la Logique Avancée (Defense / Attaque)
    var effectID: String? = nil
    var durationMinutes: Int = 0
    var isConsumable: Bool = false
    
    // --- ON DÉPLACE ACTE ICI ---
    // En le mettant à la fin, il correspondra à l'ordre de tes listes
    let acte: Int
}
