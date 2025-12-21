import SwiftUI
import Combine

class PoopEntityManager: ObservableObject {
    @Published var fallingPoops: [FallingPoop] = []
    private var fallingPoopTimer: Timer?
    
    func generatePoopRain(count: Int) {
        guard fallingPoops.count < 60 else { return }
        let screen = UIScreen.main.bounds
        
        for _ in 0..<count {
            let p = FallingPoop(
                x: CGFloat.random(in: 0...screen.width),
                y: CGFloat.random(in: -screen.height/2...0),
                size: CGFloat.random(in: 15...35),
                rotation: Angle.degrees(Double.random(in: -180...180)),
                duration: Double.random(in: 5...10)
            )
            
            DispatchQueue.main.async {
                self.fallingPoops.append(p)
            }
        }
    }

    func startFallingPoopTimer() {
        self.fallingPoopTimer?.invalidate()
        self.fallingPoopTimer = Timer.scheduledTimer(withTimeInterval: 1/20, repeats: true) { _ in
            DispatchQueue.main.async {
                for i in self.fallingPoops.indices {
                    self.fallingPoops[i].y += (50 / self.fallingPoops[i].duration) * (1/20) * 100
                }
                self.fallingPoops.removeAll { $0.y > UIScreen.main.bounds.height * 1.5 }
            }
        }
    }
}
