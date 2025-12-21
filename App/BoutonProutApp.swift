//  BoutonProutApp.swift
//  BoutonProut

import SwiftUI
import Firebase // <-- Ajout 1

@main
struct BoutonProutApp: App {
    
    init() { // <-- Ajout 2 : Initialisation de Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
