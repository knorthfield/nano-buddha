import SwiftUI

/// Scattered white dots on a black background, shared by every screen.
/// Fixed seed so the stars stay put across redraws. Same look on every screen.
struct Starfield: View {
    var secondsPerTurn: Double = 480

    private let starOpacity = 0.7

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var angle = 0.0
    private let frameRate = 30.0
    private let tick = Timer.publish(every: 1 / 30, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            let side = max(geometry.size.width, geometry.size.height) * 1.5
            canvas
                .frame(width: side, height: side)
                .rotationEffect(.degrees(angle))
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .background(Color.black)
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onReceive(tick) { _ in
            guard !reduceMotion else { return }
            angle += 360 / secondsPerTurn / frameRate
        }
    }

    private var canvas: some View {
        Canvas { context, size in
            var generator = SeededGenerator(seed: 7)
            drawNebula(in: &context, size: size, generator: &generator)
            for _ in 0..<140 {
                let x = CGFloat.random(in: 0...size.width, using: &generator)
                let y = CGFloat.random(in: 0...size.height, using: &generator)
                let radius = CGFloat.random(in: 0.4...1.6, using: &generator)
                let alpha = Double.random(in: 0.25...0.9, using: &generator) * starOpacity
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
            }
        }
    }

    /// Small soft wisps scattered away from the middle, so the centre stays dark behind the disc.
    private func drawNebula(in context: inout GraphicsContext, size: CGSize,
                            generator: inout SeededGenerator) {
        let tan = Color.accentColor
        let violet = Color(red: 0.45, green: 0.30, blue: 0.75)
        let middle = CGPoint(x: size.width / 2, y: size.height / 2)
        for index in 0..<8 {
            let tint = (index % 2 == 0 ? tan : violet).opacity(Double.random(in: 0.18...0.3, using: &generator))
            let direction = Double(index) * .pi / 4 + Double.random(in: -0.3...0.3, using: &generator)
            let distance = size.width * CGFloat.random(in: 0.15...0.42, using: &generator)
            let radius = size.width * CGFloat.random(in: 0.05...0.11, using: &generator)
            let centre = CGPoint(x: middle.x + cos(direction) * distance,
                                 y: middle.y + sin(direction) * distance)
            let stretch = CGFloat.random(in: 1.6...2.8, using: &generator)
            let tilt = Double.random(in: 0...(.pi), using: &generator)
            // Draw a circle-shaped gradient, then stretch and tilt it into a wisp.
            context.drawLayer { layer in
                layer.translateBy(x: centre.x, y: centre.y)
                layer.rotate(by: .radians(tilt))
                layer.scaleBy(x: stretch, y: 1)
                let rect = CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)
                layer.fill(Path(ellipseIn: rect),
                           with: .radialGradient(Gradient(colors: [tint, .clear]), center: .zero,
                                                 startRadius: 0, endRadius: radius))
            }
        }
    }
}

/// SplitMix64: small, deterministic, good enough for star positions.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
