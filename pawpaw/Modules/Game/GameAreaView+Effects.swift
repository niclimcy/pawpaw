//
//  GameAreaView+Effects.swift
//  pawpaw
//

import UIKit

/// Sparkly feedback effects for the play field.
extension GameAreaView {
    private static let starImage: CGImage? = {
        let size = CGSize(width: 24, height: 24)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            let path = UIBezierPath()
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            for i in 0..<8 {
                let radius = i % 2 == 0 ? size.width / 2 : size.width / 6
                let angle = CGFloat(i) * .pi / 4 - .pi / 2
                let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.close()
            UIColor.white.setFill()
            path.fill()
        }
        return image.cgImage
    }()

    private static let dotImage: CGImage? = {
        let size = CGSize(width: 12, height: 12)
        return UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
        }.cgImage
    }()

    /// Full celebration: sparkle burst, shockwave rings, flash and floating score.
    func playCatchEffects(points: Int, at position: CGPoint) {
        emitSparkles(at: position, bigBurst: points >= 20)
        emitRing(at: position, color: Theme.gold, endRadius: 110, lineWidth: 5)
        emitRing(at: position, color: .white, endRadius: 70, lineWidth: 3, delay: 0.06)
        flash(at: position)
        showPoints(points, at: position)
    }

    /// A small ripple when the cat taps empty crate.
    func playMissEffect(at position: CGPoint) {
        emitRing(at: position, color: Theme.text.withAlphaComponent(0.6), endRadius: 28, lineWidth: 2)
    }

    /// A tiny, quickly fading ripple left behind a dragging paw.
    func playTrailEffect(at position: CGPoint) {
        emitRing(at: position, color: Theme.text.withAlphaComponent(0.35), endRadius: 18, lineWidth: 1.5)
    }

    private func emitSparkles(at position: CGPoint, bigBurst: Bool) {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = position
        emitter.emitterShape = .point
        emitter.renderMode = .additive
        emitter.birthRate = 1

        // Keep it subtle: two colours, a handful of stars and a couple of dots.
        let palette: [UIColor] = [Theme.gold, .white]
        var cells: [CAEmitterCell] = []
        for color in palette {
            cells.append(makeCell(image: Self.starImage, color: color, count: bigBurst ? 4 : 2, big: true))
        }
        cells.append(makeCell(image: Self.dotImage, color: Theme.gold, count: bigBurst ? 3 : 1, big: false))
        emitter.emitterCells = cells
        layer.addSublayer(emitter)

        // One short pulse of particles, then let them fade out.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { emitter.birthRate = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { emitter.removeFromSuperlayer() }
    }

    private func makeCell(image: CGImage?, color: UIColor, count: Int, big: Bool) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = image
        cell.color = color.cgColor
        cell.birthRate = Float(count) / 0.08
        cell.lifetime = 1.0
        cell.lifetimeRange = 0.4
        cell.velocity = big ? 220 : 140
        cell.velocityRange = 90
        cell.emissionRange = .pi * 2
        cell.yAcceleration = 260
        cell.scale = big ? 0.9 : 0.7
        cell.scaleRange = 0.4
        cell.scaleSpeed = -0.5
        cell.spin = 3
        cell.spinRange = 6
        cell.alphaSpeed = -1.1
        return cell
    }
}
