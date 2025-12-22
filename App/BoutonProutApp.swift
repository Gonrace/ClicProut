import SwiftUI
import Firebase

@main
struct BoutonProutApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            // On appelle ContentView sans arguments car il a son propre init()
            ContentView()
        }
    }
}
