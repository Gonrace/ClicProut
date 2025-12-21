import SwiftUI

struct FallingPoop: Identifiable {
    let id = UUID()
    let emoji: String = "💩"
    let x: CGFloat
    var y: CGFloat = 0
    let size: CGFloat
    let rotation: Angle
    let duration: Double
}
