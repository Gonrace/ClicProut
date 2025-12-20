import SwiftUI
import MediaPlayer

/// Un composant invisible qui permet d'écouter les changements de volume
/// physique du téléphone sans afficher la barre de volume système.
struct VolumeObserver: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.alpha = 0.001 // Presque invisible
        view.addSubview(volumeView)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
