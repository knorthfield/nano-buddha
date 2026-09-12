import SwiftUI

/// A two-arm spiral galaxy on a black background, shared by every screen.
/// Fixed seed so the stars stay put across redraws. The whole field turns
/// slowly about the screen centre, so the arms read as a flowing stream.
/// The field is drawn as three depth layers that share the rotation but
/// drift on a slow circle by different amounts, so near stars sway more
/// than far ones (parallax) while the arms keep their shape.
struct Starfield: View {
    var secondsPerTurn: Double = 480

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var angle = 0.0
    @State private var driftPhase = 0.0
    private let frameRate = 30.0
    private let driftSecondsPerTurn = 24.0
    private let driftRadius: CGFloat = 20
    private let tick = Timer.publish(every: 1 / 30, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            let side = max(geometry.size.width, geometry.size.height) * 1.5
            ZStack {
                ForEach(StarLayer.Depth.allCases, id: \.self) { depth in
                    StarLayer(depth: depth)
                        .frame(width: side, height: side)
                        .offset(x: driftRadius * depth.drift * cos(driftPhase),
                                y: driftRadius * depth.drift * sin(driftPhase))
                }
            }
            .rotationEffect(.degrees(angle))
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .background(Color.black)
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onReceive(tick) { _ in
            guard !reduceMotion else { return }
            angle -= 360 / secondsPerTurn / frameRate
            driftPhase += 2 * .pi / driftSecondsPerTurn / frameRate
        }
    }
}

/// One depth slice of the galaxy. Every layer walks the same seeded random
/// sequence and only fills the stars that belong to its depth, so the three
/// layers stack into the same picture as one canvas would draw.
private struct StarLayer: View {
    enum Depth: CaseIterable {
        case far, mid, near

        /// How far the layer sways relative to the mid layer.
        var drift: CGFloat {
            switch self {
            case .far: 0.35
            case .mid: 1
            case .near: 3
            }
        }
    }

    let depth: Depth

    private let starOpacity = 0.7
    private let violet = Color(red: 0.45, green: 0.30, blue: 0.75)

    var body: some View {
        Canvas { context, size in
            var generator = SeededGenerator(seed: 7)
            drawBackgroundStars(in: &context, size: size, generator: &generator)
            drawCore(in: &context, size: size, generator: &generator)
            for arm in 0..<2 {
                let armAngle = Double(arm) * .pi
                drawArmGlow(in: &context, size: size, armAngle: armAngle, generator: &generator)
                drawArmStars(in: &context, size: size, armAngle: armAngle, generator: &generator)
            }
        }
    }

    // MARK: Spiral geometry

    /// The arms wind a bit more than one full turn, from just outside the sit disc to past the screen edges.
    private let armTurns = 2.2 * Double.pi

    private func armPoint(t: Double, armAngle: Double, size: CGSize) -> CGPoint {
        let innerRadius = size.width * 0.07
        let outerRadius = size.width * 0.35
        let growth = log(outerRadius / innerRadius) / armTurns
        let theta = t * armTurns
        let radius = innerRadius * exp(growth * theta)
        return CGPoint(x: size.width / 2 + cos(theta + armAngle) * radius,
                       y: size.height / 2 + sin(theta + armAngle) * radius)
    }

    private func armSpread(t: Double, size: CGSize) -> CGFloat {
        let point = armPoint(t: t, armAngle: 0, size: size)
        let radius = hypot(point.x - size.width / 2, point.y - size.height / 2)
        return size.width * 0.025 + radius * 0.05
    }

    // MARK: Drawing

    /// The far layer: faint stars behind the galaxy.
    private func drawBackgroundStars(in context: inout GraphicsContext, size: CGSize,
                                     generator: inout SeededGenerator) {
        for _ in 0..<120 {
            let centre = CGPoint(x: CGFloat.random(in: 0...size.width, using: &generator),
                                 y: CGFloat.random(in: 0...size.height, using: &generator))
            let radius = CGFloat.random(in: 0.3...1.0, using: &generator)
            let alpha = Double.random(in: 0.15...0.5, using: &generator) * starOpacity
            guard depth == .far else { continue }
            drawStar(in: &context, at: centre, radius: radius, tint: .white, alpha: alpha, halo: false)
        }
    }

    /// A soft warm glow and a light sprinkle of stars where the arms meet, behind the sit disc.
    private func drawCore(in context: inout GraphicsContext, size: CGSize, generator: inout SeededGenerator) {
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let coreRadius = size.width * 0.07
        if depth == .mid {
            drawGlow(in: &context, at: centre, radius: coreRadius, tint: Color.accentColor.opacity(0.18))
        }
        for _ in 0..<60 {
            let direction = Double.random(in: 0...(2 * .pi), using: &generator)
            let distance = coreRadius * sqrt(CGFloat.random(in: 0...1, using: &generator))
            let point = CGPoint(x: centre.x + cos(direction) * distance, y: centre.y + sin(direction) * distance)
            let radius = CGFloat.random(in: 0.3...1.2, using: &generator)
            let alpha = Double.random(in: 0.3...0.9, using: &generator) * starOpacity
            let tint = starTint(&generator)
            guard depth == .mid else { continue }
            drawStar(in: &context, at: point, radius: radius, tint: tint, alpha: alpha, halo: false)
        }
    }

    /// Soft blobs along each arm give the stream its milky band.
    private func drawArmGlow(in context: inout GraphicsContext, size: CGSize, armAngle: Double,
                             generator: inout SeededGenerator) {
        let blobs = 12
        for index in 0..<blobs {
            let t = (Double(index) + 0.5) / Double(blobs)
            let centre = armPoint(t: t, armAngle: armAngle, size: size)
            let tint = (index % 2 == 0 ? Color.accentColor : violet)
                .opacity(Double.random(in: 0.1...0.16, using: &generator))
            guard depth == .mid else { continue }
            drawGlow(in: &context, at: centre, radius: armSpread(t: t, size: size) * 2.5, tint: tint)
        }
    }

    /// Dim arm stars sit in the mid layer; the bright ones with a halo are the near layer.
    private func drawArmStars(in context: inout GraphicsContext, size: CGSize, armAngle: Double,
                              generator: inout SeededGenerator) {
        for _ in 0..<450 {
            let t = Double.random(in: 0...1, using: &generator)
            let point = armPoint(t: t, armAngle: armAngle, size: size)
            // Sum of two uniforms gives a bell shape, so stars bunch along the arm's spine.
            let across = CGFloat.random(in: -1...1, using: &generator) + CGFloat.random(in: -1...1, using: &generator)
            let scatter = across / 2 * armSpread(t: t, size: size)
            let outward = atan2(point.y - size.height / 2, point.x - size.width / 2)
            let centre = CGPoint(x: point.x + cos(outward) * scatter, y: point.y + sin(outward) * scatter)

            let bright = Double.random(in: 0...1, using: &generator) < 0.08
            let radius = bright ? CGFloat.random(in: 1.6...2.6, using: &generator)
                                : CGFloat.random(in: 0.3...1.4, using: &generator)
            let alpha = Double.random(in: 0.3...1, using: &generator) * starOpacity * (1 - 0.4 * t)
            let tint = starTint(&generator)
            guard depth == (bright ? .near : .mid) else { continue }
            drawStar(in: &context, at: centre, radius: radius, tint: tint, alpha: alpha, halo: bright)
        }
    }

    private func starTint(_ generator: inout SeededGenerator) -> Color {
        let roll = Double.random(in: 0...1, using: &generator)
        if roll < 0.6 { return .white }
        if roll < 0.85 { return Color(red: 0.78, green: 0.86, blue: 1.0) }
        return Color(red: 1.0, green: 0.8, blue: 0.62)
    }

    private func drawStar(in context: inout GraphicsContext, at centre: CGPoint, radius: CGFloat,
                          tint: Color, alpha: Double, halo: Bool) {
        if halo {
            drawGlow(in: &context, at: centre, radius: radius * 4, tint: tint.opacity(alpha * 0.35))
        }
        let rect = CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(tint.opacity(alpha)))
    }

    private func drawGlow(in context: inout GraphicsContext, at centre: CGPoint, radius: CGFloat, tint: Color) {
        let rect = CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect),
                     with: .radialGradient(Gradient(colors: [tint, .clear]), center: centre,
                                           startRadius: 0, endRadius: radius))
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
