struct GameNotification: Identifiable {
    let id: String // Le Trigger_ID
    let title: String
    let message: String
    let conditionType: String // "acte_reached", "pps_reached", etc.
    let conditionValue: String
}
