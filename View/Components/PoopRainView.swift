import SwiftUI

struct PoopRainView: View {
    let fallingPoops: [FallingPoop]
    let isEnabled: Bool
    
    var body: some View {
        ZStack {
            if isEnabled {
                // On précise id: \.id pour aider SwiftUI
                ForEach(fallingPoops, id: \.id) { poop in
                    Text(poop.emoji)
                        .font(.system(size: poop.size))
                        .rotationEffect(poop.rotation)
                        .position(x: poop.x, y: poop.y)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
