//
//  NatureBackgroundView.swift
//  pawpaw
//

import UIKit

/// Deterministic random numbers so the scenery doesn't change on every redraw.
private struct SceneryGenerator: RandomNumberGenerator {
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

/// Draws the grass, pond and snow playfields. The wooden crate has its own view.
final class NatureBackgroundView: UIView {
    private let theme: PlayfieldTheme

    init(theme: PlayfieldTheme) {
        self.theme = theme
        super.init(frame: .zero)
        isOpaque = true
        isUserInteractionEnabled = false
        contentMode = .redraw
        backgroundColor = theme.baseColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        var rng = SceneryGenerator(seed: 7)
        theme.baseColor.setFill()
        ctx.fill(bounds)

        switch theme {
        case .wood: break
        case .grass: drawGrass(rng: &rng)
        case .pond: drawPond(rng: &rng)
        case .snow: drawSnow(rng: &rng)
        }
        drawVignette(in: ctx)
    }

    /// Short blades in a few greens, leaning slightly.
    private func drawGrass(rng: inout SceneryGenerator) {
        let greens = [
            UIColor(red: 0.12, green: 0.28, blue: 0.12, alpha: 1),
            UIColor(red: 0.16, green: 0.34, blue: 0.14, alpha: 1),
            UIColor(red: 0.09, green: 0.22, blue: 0.10, alpha: 1)
        ]
        let count = Int(bounds.width * bounds.height / 260)
        for _ in 0..<count {
            let base = CGPoint(
                x: CGFloat.random(in: 0...bounds.width, using: &rng),
                y: CGFloat.random(in: 0...bounds.height, using: &rng)
            )
            let height = CGFloat.random(in: 10...24, using: &rng)
            let lean = CGFloat.random(in: -6...6, using: &rng)
            let blade = UIBezierPath()
            blade.move(to: base)
            blade.addQuadCurve(
                to: CGPoint(x: base.x + lean, y: base.y - height),
                controlPoint: CGPoint(x: base.x + lean * 0.2, y: base.y - height * 0.6)
            )
            blade.lineWidth = CGFloat.random(in: 1...2.2, using: &rng)
            blade.lineCapStyle = .round
            greens[Int.random(in: 0..<greens.count, using: &rng)].setStroke()
            blade.stroke()
        }
    }

    /// Soft concentric ripples and a few lily pads on dark water.
    private func drawPond(rng: inout SceneryGenerator) {
        for _ in 0..<14 {
            let center = CGPoint(
                x: CGFloat.random(in: 0...bounds.width, using: &rng),
                y: CGFloat.random(in: 0...bounds.height, using: &rng)
            )
            for ring in 1...3 {
                let radius = CGFloat(ring) * CGFloat.random(in: 14...24, using: &rng)
                let oval = UIBezierPath(ovalIn: CGRect(
                    x: center.x - radius, y: center.y - radius * 0.6,
                    width: radius * 2, height: radius * 1.2
                ))
                oval.lineWidth = 1.5
                UIColor(red: 0.45, green: 0.70, blue: 0.85, alpha: 0.16 / CGFloat(ring)).setStroke()
                oval.stroke()
            }
        }
        for _ in 0..<7 {
            let size = CGFloat.random(in: 26...44, using: &rng)
            let pad = CGRect(
                x: CGFloat.random(in: 0...bounds.width, using: &rng),
                y: CGFloat.random(in: 0...bounds.height, using: &rng),
                width: size, height: size * 0.85
            )
            UIColor(red: 0.12, green: 0.34, blue: 0.22, alpha: 0.9).setFill()
            UIBezierPath(ovalIn: pad).fill()
            UIColor(red: 0.04, green: 0.12, blue: 0.20, alpha: 1).setFill()
            // A small notch makes it read as a lily pad.
            UIBezierPath(rect: CGRect(x: pad.midX, y: pad.midY - 1.5, width: size / 2, height: 3)).fill()
        }
    }

    /// Drifts of snowflakes and a few soft mounds.
    private func drawSnow(rng: inout SceneryGenerator) {
        for _ in 0..<9 {
            let width = CGFloat.random(in: 90...220, using: &rng)
            let mound = CGRect(
                x: CGFloat.random(in: -40...bounds.width, using: &rng),
                y: CGFloat.random(in: 0...bounds.height, using: &rng),
                width: width, height: width * 0.35
            )
            UIColor.white.withAlphaComponent(0.06).setFill()
            UIBezierPath(ovalIn: mound).fill()
        }
        let flakes = Int(bounds.width * bounds.height / 3_000)
        for _ in 0..<flakes {
            let size = CGFloat.random(in: 1.5...4, using: &rng)
            let flake = CGRect(
                x: CGFloat.random(in: 0...bounds.width, using: &rng),
                y: CGFloat.random(in: 0...bounds.height, using: &rng),
                width: size, height: size
            )
            UIColor.white.withAlphaComponent(CGFloat.random(in: 0.2...0.6, using: &rng)).setFill()
            UIBezierPath(ovalIn: flake).fill()
        }
    }

    private func drawVignette(in ctx: CGContext) {
        let colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.5).cgColor] as CFArray
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.45, 1]) else { return }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = hypot(bounds.width, bounds.height) / 2
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
    }
}
