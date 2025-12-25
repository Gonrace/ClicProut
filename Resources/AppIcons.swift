import SwiftUI

enum AppIcon {
    // Menus principaux
    case shop, inventory, leaderboard, stats, social, debug
    
    // Économie
    case currency, prestige
    
    // Actions
    case close, delete, success
    
    // Cette fonction retourne l'icône correspondante
    var view: AnyView {
        switch self {
        case .shop:
            return AnyView(Image(systemName: "cart.fill"))
        case .inventory:
            return AnyView(Image(systemName: "archivebox.fill"))
        case .leaderboard:
            return AnyView(Image(systemName: "trophy.fill"))
        case .stats:
            return AnyView(Image(systemName: "chart.bar.fill"))
        case .social:
            return AnyView(Image(systemName: "person.2.fill"))
        case .debug:
            return AnyView(Image(systemName: "ant.fill"))
            
        // Pour les Emojis (Économie)
        case .currency:
            return AnyView(Text("💩"))
        case .prestige:
            return AnyView(Text("🧻"))
            
        case .close:
            return AnyView(Image(systemName: "xmark.circle.fill"))
        case .success:
            return AnyView(Image(systemName: "checkmark.seal.fill"))
        default:
            return AnyView(Image(systemName: "questionmark.circle"))
        }
    }
}
