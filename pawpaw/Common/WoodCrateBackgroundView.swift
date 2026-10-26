//
//  WoodCrateBackgroundView.swift
//  pawpaw
//

import UIKit

/// Deterministic random numbers so the wood grain doesn't change on every redraw.
private struct SeededGenerator: RandomNumberGenerator {
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

/// Draws a dark wooden crate: horizontal planks with grain, seams, nails and a vignette.
final class WoodCrateBackgroundView: UIView {
    private let plankHeight: CGFloat = 96

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = true
        isUserInteractionEnabled = false
        contentMode = .redraw
        backgroundColor = Theme.background
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        var rng = SeededGenerator(seed: 42)

        let plankCount = Int(ceil(bounds.height / plankHeight))
        for index in 0..<plankCount {
            let plank = CGRect(x: 0, y: CGFloat(index) * plankHeight, width: bounds.width, height: plankHeight)
            drawPlank(plank, in: ctx, rng: &rng)
        }
        drawVignette(in: ctx)
    }

    private func drawPlank(_ plank: CGRect, in ctx: CGContext, rng: inout SeededGenerator) {
        // Base tone, varied per plank.
        let shade = CGFloat.random(in: -0.025...0.035, using: &rng)
        UIColor(red: 0.20 + shade, green: 0.125 + shade * 0.7, blue: 0.075 + shade * 0.4, alpha: 1).setFill()
        ctx.fill(plank)

        // Grain lines.
        for _ in 0..<14 {
            let y = plank.minY + CGFloat.random(in: 4...(plank.height - 4), using: &rng)
            let amplitude = CGFloat.random(in: 1...4, using: &rng)
            let startX = CGFloat.random(in: -40...bounds.width * 0.4, using: &rng)
            let endX = startX + CGFloat.random(in: bounds.width * 0.3...bounds.width, using: &rng)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: startX, y: y))
            path.addCurve(to: CGPoint(x: endX, y: y + CGFloat.random(in: -3...3, using: &rng)),
                          controlPoint1: CGPoint(x: startX + (endX - startX) * 0.3, y: y - amplitude),
                          controlPoint2: CGPoint(x: startX + (endX - startX) * 0.7, y: y + amplitude))
            path.lineWidth = CGFloat.random(in: 0.6...1.6, using: &rng)
            UIColor.black.withAlphaComponent(CGFloat.random(in: 0.08...0.22, using: &rng)).setStroke()
            path.stroke()
        }

        // A knot or two.
        for _ in 0..<Int.random(in: 0...1, using: &rng) {
            let size = CGFloat.random(in: 14...26, using: &rng)
            let knot = CGRect(x: CGFloat.random(in: 40...(bounds.width - 60), using: &rng),
                              y: plank.midY - size / 2 + CGFloat.random(in: -10...10, using: &rng),
                              width: size * 1.6, height: size)
            UIColor.black.withAlphaComponent(0.28).setFill()
            UIBezierPath(ovalIn: knot).fill()
            UIColor.black.withAlphaComponent(0.18).setStroke()
            UIBezierPath(ovalIn: knot.insetBy(dx: -4, dy: -3)).stroke()
        }

        // Highlight on top edge and dark seam on the bottom edge.
        UIColor.white.withAlphaComponent(0.05).setFill()
        ctx.fill(CGRect(x: plank.minX, y: plank.minY, width: plank.width, height: 2))
        UIColor.black.withAlphaComponent(0.65).setFill()
        ctx.fill(CGRect(x: plank.minX, y: plank.maxY - 3, width: plank.width, height: 3))

        // Nails at both ends.
        for x in [CGFloat(18), bounds.width - 18] {
            let nail = CGRect(x: x - 5, y: plank.midY - 5, width: 10, height: 10)
            UIColor.black.withAlphaComponent(0.5).setFill()
            UIBezierPath(ovalIn: nail.offsetBy(dx: 1, dy: 1.5)).fill()
            UIColor(white: 0.32, alpha: 1).setFill()
            UIBezierPath(ovalIn: nail).fill()
            UIColor(white: 0.6, alpha: 0.8).setFill()
            UIBezierPath(ovalIn: CGRect(x: nail.minX + 2, y: nail.minY + 2, width: 3, height: 3)).fill()
        }
    }

    private func drawVignette(in ctx: CGContext) {
        let colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.55).cgColor] as CFArray
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.45, 1]) else { return }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = hypot(bounds.width, bounds.height) / 2
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
    }
}

extension UIViewController {
    /// Puts the dark wooden crate behind everything else in the view.
    func installWoodBackground() {
        let wood = WoodCrateBackgroundView()
        wood.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(wood, at: 0)
        NSLayoutConstraint.activate([
            wood.topAnchor.constraint(equalTo: view.topAnchor),
            wood.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            wood.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wood.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
