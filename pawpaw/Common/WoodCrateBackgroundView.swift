//
//  WoodCrateBackgroundView.swift
//  pawpaw
//

import UIKit

/// Draws a dark wooden crate: horizontal planks with grain, seams, nails and a vignette.
/// A fixed seed keeps the grain the same every time it is drawn.
final class WoodCrateBackgroundView: CachedBackgroundView {
    private let plankHeight: CGFloat = 96

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        backgroundColor = Theme.background
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawBackground(in ctx: CGContext, size: CGSize) {
        let bounds = CGRect(origin: .zero, size: size)
        Theme.background.setFill()
        ctx.fill(bounds)
        var rng = SeededGenerator(seed: 42)

        let plankCount = Int(ceil(bounds.height / plankHeight))
        for index in 0..<plankCount {
            let plank = CGRect(x: 0, y: CGFloat(index) * plankHeight, width: bounds.width, height: plankHeight)
            drawPlank(plank, width: bounds.width, in: ctx, rng: &rng)
        }
        Self.drawVignette(in: ctx, size: size, darkness: 0.55)
    }

    private func drawPlank(_ plank: CGRect, width: CGFloat, in ctx: CGContext, rng: inout SeededGenerator) {
        let bounds = CGRect(x: 0, y: 0, width: width, height: plank.maxY)
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

        // A knot or two, on fields wide enough to hold one between the nails.
        let knots = Int.random(in: 0...1, using: &rng)
        for _ in 0..<(bounds.width > 120 ? knots : 0) {
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
}

extension UIViewController {
    private static let backgroundTag = 9_002

    /// Puts the theme's playfield behind everything else, replacing any earlier one.
    func installBackground(theme: PlayfieldTheme) {
        view.viewWithTag(Self.backgroundTag)?.removeFromSuperview()
        let background: UIView = theme == .wood ? WoodCrateBackgroundView() : NatureBackgroundView(theme: theme)
        background.tag = Self.backgroundTag
        background.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(background, at: 0)
        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: view.topAnchor),
            background.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            background.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
