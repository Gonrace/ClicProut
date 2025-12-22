import Foundation
import FirebaseDatabase
import Combine

class CloudConfigManager: ObservableObject {
    // Force l'utilisation du serveur Europe
    private let ref = Database.database(url: "https://clicprout-default-rtdb.europe-west1.firebasedatabase.app").reference()

    // On expose cette référence pour les autres managers
    var databaseRef: DatabaseReference {
        return ref
    }
    
    // --- DONNÉES CLOUD ---
    @Published var allItems: [ShopItem] = []
    @Published var actesInfo: [Int: ActeMetadata] = [:]
    @Published var config = GlobalConfig()
    @Published var isMaintenanceMode: Bool = false
    @Published var remoteNotifications: [GameNotification] = []

    func startFirebaseSync(notificationCheck: @escaping () -> Void) {
        // Observer les items du shop
        ref.child("shop_items").observe(.value) { snapshot in
            guard let value = snapshot.value as? [String: [String: Any]] else { return }
            let items = value.values.compactMap { self.parseItem(dict: $0) }
            DispatchQueue.main.async {
                self.allItems = items
            }
        }
        
        // Observer les Actes
        ref.child("metadata_actes").observe(.value) { snapshot in
            var fetchedDict: [String: [String: Any]] = [:]
            if let array = snapshot.value as? [Any] {
                for (index, val) in array.enumerated() {
                    if let dict = val as? [String: Any] { fetchedDict["\(index)"] = dict }
                }
            } else if let dict = snapshot.value as? [String: [String: Any]] {
                fetchedDict = dict
            }

            var newActes: [Int: ActeMetadata] = [:]
            for (_, dict) in fetchedDict {
                let rawID = dict["Acte"] ?? 0
                if let id = Int("\(rawID)"), id > 0 {
                    newActes[id] = ActeMetadata(
                        id: id,
                        title: dict["Titre"] as? String ?? "Acte \(id)",
                        description: dict["Description"] as? String ?? "",
                        threshold: Double("\(dict["Seuil_Deblocage"] ?? 0.9)") ?? 0.9
                    )
                }
            }
            DispatchQueue.main.async { self.actesInfo = newActes }
        }

        // Observer les notifications
        ref.child("notifications").observe(.value) { snapshot in
            guard let value = snapshot.value as? [String: [String: Any]] else { return }
            let notifs = value.map { (key, val) in
                GameNotification(
                    id: key,
                    title: val["Titre"] as? String ?? "",
                    message: val["Message"] as? String ?? "",
                    conditionType: val["Condition_Type"] as? String ?? "",
                    conditionValue: "\(val["Condition_Value"] ?? "")"
                )
            }
            DispatchQueue.main.async {
                self.remoteNotifications = notifs
                notificationCheck() // On prévient GameData de vérifier les notifs
            }
        }

        // Observer la logique PVP
        ref.child("logic_pvp").observe(.value) { snapshot in
            guard let value = snapshot.value as? [String: [String: Any]] else { return }
            var logic: [String: [String]] = [:]
            for (_, dict) in value {
                if let atk = dict["Attack_Effect_ID"] as? String,
                   let def = dict["Defense_Effect_ID"] as? String {
                    logic[atk, default: []].append(def)
                }
            }
            CombatLogic.defensesForAttack = logic
        }

        // Config Globale
        ref.child("global_config").observe(.value) { snapshot in
            guard let value = snapshot.value as? [String: [String: Any]] else { return }
            DispatchQueue.main.async {
                if let pMult = Double("\(value["price_multiplier"]?["Valeur"] ?? 1.15)") { self.config.priceMultiplier = pMult }
                if let bClick = Int("\(value["base_click_value"]?["Valeur"] ?? 1)") { self.config.baseClickValue = bClick }
                let status = value["server_status"]?["Valeur"] as? String ?? "online"
                self.isMaintenanceMode = (status == "maintenance")
            }
        }
    }

    private func parseItem(dict: [String: Any]) -> ShopItem? {
        guard let name = dict["Nom"] as? String else { return nil }
        let toDouble = { (v: Any?) -> Double in
            if let d = v as? Double { return d }
            if let s = v as? String { return Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0.0 }
            return Double("\(v ?? 0)") ?? 0.0
        }
        return ShopItem(
            name: name,
            category: ItemCategory(rawValue: dict["Categorie"] as? String ?? "production") ?? .production,
            acte: Int("\(dict["Acte"] ?? 1)") ?? 1,
            baseCost: Int("\(dict["Cout_Base"] ?? 0)") ?? 0,
            currency: (dict["Monnaie"] as? String == "goldenPaper") ? .goldenPaper : .pets,
            dpsRate: toDouble(dict["PPS_Rate"]),
            clickMultiplier: Int("\(dict["PPC_Bonus"] ?? 0)") ?? 0,
            multPPS: toDouble(dict["Mult_PPS"]) == 0 ? 1.0 : toDouble(dict["Mult_PPS"]),
            multPPC: toDouble(dict["Mult_PPC"]) == 0 ? 1.0 : toDouble(dict["Mult_PPC"]),
            lossRate: toDouble(dict["Loss_Rate"]),
            durationSec: Int("\(dict["Duration_Sec"] ?? 0)") ?? 0,
            emoji: dict["Emoji"] as? String ?? "❓",
            description: dict["Description"] as? String ?? "",
            requiredItem: (dict["Req_Item"] as? String == "" || dict["Req_Item"] as? String == nil) ? nil : dict["Req_Item"] as? String,
            requiredItemCount: Int("\(dict["Req_Count"] ?? 0)") ?? 0,
            effectID: dict["Effect_ID"] as? String == "" ? nil : dict["Effect_ID"] as? String
        )
    }
}
