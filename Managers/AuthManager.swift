import Foundation
import FirebaseAuth
import Combine

class AuthManager: ObservableObject {
    @Published var user: User?

    init() {
        self.user = Auth.auth().currentUser
        
        // Si l'utilisateur n'est pas connecté, on le connecte anonymement
        if self.user == nil {
            signInAnonymously()
        }
    }

    func signInAnonymously() {
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                print("Erreur de connexion anonyme : \(error.localizedDescription)")
                return
            }
            self.user = authResult?.user
            print("Connecté anonymement avec l'ID : \(self.user?.uid ?? "")")
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        self.user = nil
    }
}
