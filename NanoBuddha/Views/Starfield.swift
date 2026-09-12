import SwiftUI

/// A two-arm spiral galaxy on black in dark mode; grains of sand on old paper in light mode.
/// Shared by every screen. Fixed seed so the stars stay put across redraws. The whole field
/// turns slowly about the screen centre, so the arms read as a flowing stream.
/// The bright halo stars sit in a layer of their own and travel inward
/// along the arms, which gives the stream depth and motion.
struct Starfield: View {
    var secondsPerTurn: Double = 480

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var angle = 0.0
    @State private var flow = 0.0
    private let frameRate = 30.0
    /// How long a bright star of average speed takes to travel the full length of an arm.
    private let flowSecondsPerArm = 180.0
    private let tick = Timer.publish(every: 1 / 30, on: .main, in: .common).autoconnect()

    var body: some View {
        let palette = colorScheme == .dark ? Palette.space : Palette.paper
        GeometryReader { geometry in
            let side = max(geometry.size.width, geometry.size.height) * 1.5
            ZStack {
                GalaxyLayer(palette: palette)
                FlowingStarsLayer(palette: palette, flow: flow)
            }
            .frame(width: side, height: side)
            .rotationEffect(.degrees(angle))
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .background(palette.background)
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onReceive(tick) { _ in
            guard !reduceMotion else { return }
            angle -= 360 / secondsPerTurn / frameRate
            flow += 1 / flowSecondsPerArm / frameRate
        }
    }
}

// MARK: Palette

/// The colours of one appearance. Geometry, seeds and counts are the same in both.
private struct Palette {
    let background: Color
    /// Three tints a star (or grain) can roll: common, cool and warm.
    let starTints: [Color]
    let coreTint: Color
    let armTints: [Color]
    /// Light mode only: mottle the background like old paper before the grains go on.
    let paperGrain: Bool

    static let space = Palette(
        background: .black,
        starTints: [.white, Color(red: 0.78, green: 0.86, blue: 1.0), Color(red: 1.0, green: 0.8, blue: 0.62)],
        coreTint: .accentColor,
        armTints: [.accentColor, Color(red: 0.45, green: 0.30, blue: 0.75)],
        paperGrain: false)

    static let paper = Palette(
        background: Color(red: 0.97, green: 0.94, blue: 0.87),
        starTints: [Color(red: 0.55, green: 0.42, blue: 0.28), Color(red: 0.45, green: 0.33, blue: 0.22),
                    Color(red: 0.65, green: 0.50, blue: 0.30)],
        coreTint: .accentColor,
        armTints: [.accentColor, Color(red: 0.50, green: 0.42, blue: 0.34)],
        paperGrain: true)
}

// MARK: Spiral geometry

/// The arms wind a bit more than one full turn, from just outside the sit disc to past the screen edges.
private enum Spiral {
    static let armTurns = 2.2 * Double.pi
    static let starOpacity = 0.7

    static func armPoint(t: Double, armAngle: Double, size: CGSize) -> CGPoint {
        let innerRadius = size.width * 0.07
        let outerRadius = size.width * 0.35
        let growth = log(outerRadius / innerRadius) / armTurns
        let theta = t * armTurns
        let radius = innerRadius * exp(growth * theta)
        return CGPoint(x: size.width / 2 + cos(theta + armAngle) * radius,
                       y: size.height / 2 + sin(theta + armAngle) * radius)
    }

    static func armSpread(t: Double, size: CGSize) -> CGFloat {
        let point = armPoint(t: t, armAngle: 0, size: size)
        let radius = hypot(point.x - size.width / 2, point.y - size.height / 2)
        return size.width * 0.025 + radius * 0.05
    }

    /// A point on the arm pushed across it by `across` (−1...1) times the arm's spread.
    static func scatteredPoint(t: Double, armAngle: Double, across: CGFloat, size: CGSize) -> CGPoint {
        let point = armPoint(t: t, armAngle: armAngle, size: size)
        let scatter = across * armSpread(t: t, size: size)
        let outward = atan2(point.y - size.height / 2, point.x - size.width / 2)
        return CGPoint(x: point.x + cos(outward) * scatter, y: point.y + sin(outward) * scatter)
    }

    /// Index into `Palette.starTints`: 60 % common, 25 % cool, 15 % warm.
    static func starTintIndex(_ generator: inout SeededGenerator) -> Int {
        let roll = Double.random(in: 0...1, using: &generator)
        if roll < 0.6 { return 0 }
        if roll < 0.85 { return 1 }
        return 2
    }

    static func drawStar(in context: inout GraphicsContext, at centre: CGPoint, radius: CGFloat,
                         tint: Color, alpha: Double, halo: Bool) {
        if halo {
            drawGlow(in: &context, at: centre, radius: radius * 4, tint: tint.opacity(alpha * 0.35))
        }
        let rect = CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(tint.opacity(alpha)))
    }

    static func drawGlow(in context: inout GraphicsContext, at centre: CGPoint, radius: CGFloat, tint: Color) {
        let rect = CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect),
                     with: .radialGradient(Gradient(colors: [tint, .clear]), center: centre,
                                           startRadius: 0, endRadius: radius))
    }
}

// MARK: Static galaxy

/// Background stars, the core, the arm glow and the dim arm stars. Drawn once; only rotated.
private struct GalaxyLayer: View {
    let palette: Palette

    var body: some View {
        Canvas { context, size in
            if palette.paperGrain {
                var paperGenerator = SeededGenerator(seed: 3)
                drawPaperGrain(in: &context, size: size, generator: &paperGenerator)
            }
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

    /// Soft blotches and fine speckles that mottle the paper. Its own generator, so the
    /// galaxy's seed still gives the same layout in both appearances.
    private func drawPaperGrain(in context: inout GraphicsContext, size: CGSize,
                                generator: inout SeededGenerator) {
        for _ in 0..<8 {
            let centre = CGPoint(x: CGFloat.random(in: 0...size.width, using: &generator),
                                 y: CGFloat.random(in: 0...size.height, using: &generator))
            let radius = CGFloat.random(in: 0.15...0.4, using: &generator) * size.width
            Spiral.drawGlow(in: &context, at: centre, radius: radius, tint: palette.starTints[0].opacity(0.05))
        }
        for _ in 0..<2000 {
            let centre = CGPoint(x: CGFloat.random(in: 0...size.width, using: &generator),
                                 y: CGFloat.random(in: 0...size.height, using: &generator))
            let radius = CGFloat.random(in: 0.3...0.8, using: &generator)
            let alpha = Double.random(in: 0.04...0.10, using: &generator)
            let tint = palette.starTints[Spiral.starTintIndex(&generator)]
            Spiral.drawStar(in: &context, at: centre, radius: radius, tint: tint, alpha: alpha, halo: false)
        }
    }

    private func drawBackgroundStars(in context: inout GraphicsContext, size: CGSize,
                                     generator: inout SeededGenerator) {
        for _ in 0..<120 {
            let centre = CGPoint(x: CGFloat.random(in: 0...size.width, using: &generator),
                                 y: CGFloat.random(in: 0...size.height, using: &generator))
            let radius = CGFloat.random(in: 0.3...1.0, using: &generator)
            let alpha = Double.random(in: 0.15...0.5, using: &generator) * Spiral.starOpacity
            Spiral.drawStar(in: &context, at: centre, radius: radius, tint: palette.starTints[0],
                            alpha: alpha, halo: false)
        }
    }

    /// A soft warm glow and a light sprinkle of stars where the arms meet, behind the sit disc.
    private func drawCore(in context: inout GraphicsContext, size: CGSize, generator: inout SeededGenerator) {
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let coreRadius = size.width * 0.07
        Spiral.drawGlow(in: &context, at: centre, radius: coreRadius, tint: palette.coreTint.opacity(0.18))
        for _ in 0..<60 {
            let direction = Double.random(in: 0...(2 * .pi), using: &generator)
            let distance = coreRadius * sqrt(CGFloat.random(in: 0...1, using: &generator))
            let point = CGPoint(x: centre.x + cos(direction) * distance, y: centre.y + sin(direction) * distance)
            let radius = CGFloat.random(in: 0.3...1.2, using: &generator)
            let alpha = Double.random(in: 0.3...0.9, using: &generator) * Spiral.starOpacity
            let tint = palette.starTints[Spiral.starTintIndex(&generator)]
            Spiral.drawStar(in: &context, at: point, radius: radius, tint: tint, alpha: alpha, halo: false)
        }
    }

    /// Soft blobs along each arm give the stream its milky band.
    private func drawArmGlow(in context: inout GraphicsContext, size: CGSize, armAngle: Double,
                             generator: inout SeededGenerator) {
        let blobs = 12
        for index in 0..<blobs {
            let t = (Double(index) + 0.5) / Double(blobs)
            let centre = Spiral.armPoint(t: t, armAngle: armAngle, size: size)
            let tint = palette.armTints[index % 2]
                .opacity(Double.random(in: 0.1...0.16, using: &generator))
            Spiral.drawGlow(in: &context, at: centre, radius: Spiral.armSpread(t: t, size: size) * 2.5, tint: tint)
        }
    }

    private func drawArmStars(in context: inout GraphicsContext, size: CGSize, armAngle: Double,
                              generator: inout SeededGenerator) {
        for _ in 0..<420 {
            let t = Double.random(in: 0...1, using: &generator)
            // Sum of two uniforms gives a bell shape, so stars bunch along the arm's spine.
            let across = (CGFloat.random(in: -1...1, using: &generator) + CGFloat.random(in: -1...1, using: &generator)) / 2
            let centre = Spiral.scatteredPoint(t: t, armAngle: armAngle, across: across, size: size)
            let radius = CGFloat.random(in: 0.3...1.4, using: &generator)
            let alpha = Double.random(in: 0.3...1, using: &generator) * Spiral.starOpacity * (1 - 0.4 * t)
            let tint = palette.starTints[Spiral.starTintIndex(&generator)]
            Spiral.drawStar(in: &context, at: centre, radius: radius, tint: tint, alpha: alpha, halo: false)
        }
    }
}

// MARK: Flowing stars

/// The bright halo stars. Each starts at its own place on an arm and travels inward along it,
/// fading in near the edge and out near the core, then starts again from the edge.
private struct FlowingStarsLayer: View {
    let palette: Palette
    /// Arm lengths travelled so far at average speed; grows without bound.
    let flow: Double

    private struct Star {
        let armAngle: Double
        let start: Double
        let speed: Double
        let across: CGFloat
        let radius: CGFloat
        let alpha: Double
        let tintIndex: Int
    }

    private static let stars: [Star] = {
        var generator = SeededGenerator(seed: 11)
        return (0..<70).map { index in
            Star(armAngle: Double(index % 2) * .pi,
                 start: Double.random(in: 0...1, using: &generator),
                 speed: Double.random(in: 0.7...1.3, using: &generator),
                 across: (CGFloat.random(in: -1...1, using: &generator) + CGFloat.random(in: -1...1, using: &generator)) / 2,
                 radius: CGFloat.random(in: 1.6...2.6, using: &generator),
                 alpha: Double.random(in: 0.3...1, using: &generator) * Spiral.starOpacity,
                 tintIndex: Spiral.starTintIndex(&generator))
        }
    }()

    var body: some View {
        Canvas { context, size in
            for star in Self.stars {
                let travelled = star.start - flow * star.speed
                let t = travelled - floor(travelled)
                let centre = Spiral.scatteredPoint(t: t, armAngle: star.armAngle, across: star.across, size: size)
                let endFade = min(1, t * 8, (1 - t) * 8)
                let alpha = star.alpha * (1 - 0.4 * t) * endFade
                Spiral.drawStar(in: &context, at: centre, radius: star.radius, tint: palette.starTints[star.tintIndex],
                                alpha: alpha, halo: true)
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
