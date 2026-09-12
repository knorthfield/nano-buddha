// Renders the in-app spiral galaxy (NanoBuddha/Views/Starfield.swift) as a static SVG for the
// app icon. The geometry, seeds and palette are copied from Starfield.swift; keep them in step.
//
//   swift scripts/icon-stars.swift > NanoBuddha/AppIcon.icon/Assets/stars.svg

import Foundation

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

struct Point { var x: Double; var y: Double }

let iconSide = 1024.0
/// The app draws on a canvas 1.5× the screen; the icon shows a similar slice of the galaxy.
let canvasSide = iconSide * 1.5
let canvasOffset = (iconSide - canvasSide) / 2
/// App star radii are in points on a ~400 pt screen; scale them up to the 1024 px icon.
let radiusScale = 3.0

let armTurns = 2.2 * Double.pi
let starOpacity = 0.7
let white = "#FFFFFF"
let blueWhite = "#C7DBFF"
let warm = "#FFCC9E"
let accent = "#CC8C66"
let violet = "#734DBF"

func armPoint(t: Double, armAngle: Double) -> Point {
    let innerRadius = canvasSide * 0.07
    let outerRadius = canvasSide * 0.35
    let growth = log(outerRadius / innerRadius) / armTurns
    let theta = t * armTurns
    let radius = innerRadius * exp(growth * theta)
    return Point(x: canvasSide / 2 + cos(theta + armAngle) * radius,
                 y: canvasSide / 2 + sin(theta + armAngle) * radius)
}

func armSpread(t: Double) -> Double {
    let point = armPoint(t: t, armAngle: 0)
    let radius = hypot(point.x - canvasSide / 2, point.y - canvasSide / 2)
    return canvasSide * 0.025 + radius * 0.05
}

func scatteredPoint(t: Double, armAngle: Double, across: Double) -> Point {
    let point = armPoint(t: t, armAngle: armAngle)
    let scatter = across * armSpread(t: t)
    let outward = atan2(point.y - canvasSide / 2, point.x - canvasSide / 2)
    return Point(x: point.x + cos(outward) * scatter, y: point.y + sin(outward) * scatter)
}

func starTint(_ generator: inout SeededGenerator) -> String {
    let roll = Double.random(in: 0...1, using: &generator)
    if roll < 0.6 { return white }
    if roll < 0.85 { return blueWhite }
    return warm
}

var svg = ""
var gradientCount = 0

func number(_ value: Double) -> String { String(format: "%.1f", value) }

func circle(at point: Point, radius: Double, fill: String, opacity: Double) {
    svg += "  <circle cx=\"\(number(point.x + canvasOffset))\" cy=\"\(number(point.y + canvasOffset))\" "
    svg += "r=\"\(number(radius))\" fill=\"\(fill)\" opacity=\"\(String(format: "%.3f", opacity))\"/>\n"
}

/// A radial gradient fading from `tint` to clear, like Spiral.drawGlow.
func glow(at point: Point, radius: Double, tint: String, opacity: Double) {
    gradientCount += 1
    let id = "g\(gradientCount)"
    svg += "  <radialGradient id=\"\(id)\"><stop offset=\"0\" stop-color=\"\(tint)\"/>"
    svg += "<stop offset=\"1\" stop-color=\"\(tint)\" stop-opacity=\"0\"/></radialGradient>\n"
    circle(at: point, radius: radius, fill: "url(#\(id))", opacity: opacity)
}

func star(at point: Point, radius: Double, tint: String, alpha: Double, halo: Bool) {
    let scaled = radius * radiusScale
    if halo { glow(at: point, radius: scaled * 4, tint: tint, opacity: alpha * 0.35) }
    circle(at: point, radius: scaled, fill: tint, opacity: alpha)
}

svg += "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1024\" height=\"1024\" viewBox=\"0 0 1024 1024\">\n"

var generator = SeededGenerator(seed: 7)

for _ in 0..<120 {
    let centre = Point(x: Double.random(in: 0...canvasSide, using: &generator),
                       y: Double.random(in: 0...canvasSide, using: &generator))
    let radius = Double.random(in: 0.3...1.0, using: &generator)
    let alpha = Double.random(in: 0.15...0.5, using: &generator) * starOpacity
    star(at: centre, radius: radius, tint: white, alpha: alpha, halo: false)
}

let centre = Point(x: canvasSide / 2, y: canvasSide / 2)
let coreRadius = canvasSide * 0.07
glow(at: centre, radius: coreRadius, tint: accent, opacity: 0.18)
for _ in 0..<60 {
    let direction = Double.random(in: 0...(2 * .pi), using: &generator)
    let distance = coreRadius * sqrt(Double.random(in: 0...1, using: &generator))
    let point = Point(x: centre.x + cos(direction) * distance, y: centre.y + sin(direction) * distance)
    let radius = Double.random(in: 0.3...1.2, using: &generator)
    let alpha = Double.random(in: 0.3...0.9, using: &generator) * starOpacity
    star(at: point, radius: radius, tint: starTint(&generator), alpha: alpha, halo: false)
}

for arm in 0..<2 {
    let armAngle = Double(arm) * .pi
    let blobs = 12
    for index in 0..<blobs {
        let t = (Double(index) + 0.5) / Double(blobs)
        let tint = index % 2 == 0 ? accent : violet
        let opacity = Double.random(in: 0.1...0.16, using: &generator)
        glow(at: armPoint(t: t, armAngle: armAngle), radius: armSpread(t: t) * 2.5, tint: tint, opacity: opacity)
    }
    for _ in 0..<420 {
        let t = Double.random(in: 0...1, using: &generator)
        let across = (Double.random(in: -1...1, using: &generator) + Double.random(in: -1...1, using: &generator)) / 2
        let point = scatteredPoint(t: t, armAngle: armAngle, across: across)
        let radius = Double.random(in: 0.3...1.4, using: &generator)
        let alpha = Double.random(in: 0.3...1, using: &generator) * starOpacity * (1 - 0.4 * t)
        star(at: point, radius: radius, tint: starTint(&generator), alpha: alpha, halo: false)
    }
}

var brightGenerator = SeededGenerator(seed: 11)
for index in 0..<70 {
    let armAngle = Double(index % 2) * .pi
    let t = Double.random(in: 0...1, using: &brightGenerator)
    _ = Double.random(in: 0.7...1.3, using: &brightGenerator) // speed; unused when frozen
    let across = (Double.random(in: -1...1, using: &brightGenerator) + Double.random(in: -1...1, using: &brightGenerator)) / 2
    let radius = Double.random(in: 1.6...2.6, using: &brightGenerator)
    let alpha = Double.random(in: 0.3...1, using: &brightGenerator) * starOpacity
    let tint = starTint(&brightGenerator)
    let endFade = min(1, t * 8, (1 - t) * 8)
    star(at: scatteredPoint(t: t, armAngle: armAngle, across: across), radius: radius, tint: tint,
         alpha: alpha * (1 - 0.4 * t) * endFade, halo: true)
}

svg += "</svg>\n"
print(svg, terminator: "")
