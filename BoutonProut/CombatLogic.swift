import Foundation

struct CombatLogic {
    
    // MARK: - CONFIGURATION DES CONTRES
    // Clé : effectID de l'ATTAQUE (perturbateur)
    // Valeur : Liste des effectID des DÉFENSES (defense) capables de l'annuler
    static let defensesForAttack: [String: [String]] = [
        // --- ACTE 2 : ADOLESCENCE ---
        "attack_dps_reduction_50": ["defense_anti_spray"],        // Spray vs Bouchon
        "attack_loss_t1_10":       ["defense_anti_loss"],         // Pet Foireux vs Smecta
        "attack_block_click":      ["defense_anti_block"],        // Boule Puante vs Pince à linge
        
        // --- ACTE 3 : AMOUR ---
        "attack_dps_reduction_75": ["defense_anti_breakup"],      // Rupture vs Poème
        "attack_steal_rings":      ["defense_anti_theft"],        // Voleur de bague vs Coffre-fort
        "attack_click_reduction_80":["defense_anti_garlic"],      // Haleine d'ail vs Chewing-gum
        
        // --- ACTE 4 : TRAVAIL ---
        "attack_freeze_production": ["defense_anti_audit"],        // Audit vs Paradis Fiscal
        "attack_mega_nerf":         ["defense_anti_burnout"],      // Burn-out vs Pause Café
        "attack_score_steal_5":     ["defense_anti_hack"],         // Piratage vs Pare-feu
        
        // --- ACTE 5 : RETRAITE ---
        "attack_total_block":       ["defense_anti_block_total"],  // Dénonciation vs Petit-fils
        "attack_strip_upgrades":    ["defense_anti_legacy"],       // Perte héritage vs Notaire
        "attack_extreme_dps_nerf":  ["defense_anti_teeth_theft"]   // Vol de dentier vs Fixodent
    ]
    
    // MARK: - HELPERS
    
    /// Vérifie si une défense spécifique peut contrer une attaque donnée
    static func canDefend(attackID: String, defenseID: String) -> Bool {
        // On récupère la liste des défenses valides pour cette attaque
        guard let validDefenses = defensesForAttack[attackID] else { return false }
        
        // On vérifie si la défense utilisée est dans la liste
        return validDefenses.contains(defenseID)
    }
}
