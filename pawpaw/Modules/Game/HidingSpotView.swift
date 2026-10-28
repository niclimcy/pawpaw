//
//  HidingSpotView.swift
//  pawpaw
//

import UIKit

/// Something on the playfield a critter can duck under: a box on the crate, a leaf pile on grass,
/// a lily pad on the pond or a snow mound. It sits above the critters, so they vanish beneath it.
final class HidingSpotView: UIView {
    private let theme: PlayfieldTheme

    init(theme: PlayfieldTheme) {
        self.theme = theme
        super.init(frame: .zero)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        contentMode = .redraw
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.55
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 6)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let area = bounds.insetBy(dx: 6, dy: 6)
        switch theme {
        case .wood: drawBox(in: area)
        case .grass: drawLeafPile(in: area)
        case .pond: drawLilyPad(in: area)
        case .snow: drawSnowMound(in: area)
        }
    }

    /// A cardboard box seen from above, flaps folded back.
    private func drawBox(in area: CGRect) {
        let box = area.insetBy(dx: area.width * 0.08, dy: area.height * 0.08)
        UIColor(red: 0.62, green: 0.45, blue: 0.27, alpha: 1).setFill()
        UIBezierPath(roundedRect: box, cornerRadius: 8).fill()
        UIColor(red: 0.50, green: 0.35, blue: 0.20, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: box.minX, y: box.midY - 8, width: box.width, height: 16)).fill()
        UIColor.black.withAlphaComponent(0.25).setStroke()
        let seam = UIBezierPath()
        seam.move(to: CGPoint(x: box.midX, y: box.minY + 6))
        seam.addLine(to: CGPoint(x: box.midX, y: box.maxY - 6))
        seam.lineWidth = 2
        seam.stroke()
    }

    /// A heap of overlapping autumn leaves.
    private func drawLeafPile(in area: CGRect) {
        let colors = [
            UIColor(red: 0.55, green: 0.30, blue: 0.10, alpha: 1),
            UIColor(red: 0.68, green: 0.42, blue: 0.12, alpha: 1),
            UIColor(red: 0.45, green: 0.38, blue: 0.12, alpha: 1)
        ]
        let center = CGPoint(x: area.midX, y: area.midY)
        for index in 0..<11 {
            let angle = CGFloat(index) * 2.4
            let reach = area.width * (index == 0 ? 0 : 0.22)
            let leafCenter = CGPoint(x: center.x + cos(angle) * reach, y: center.y + sin(angle) * reach)
            let leaf = UIBezierPath(ovalIn: CGRect(x: -area.width * 0.2, y: -area.height * 0.11,
                                                   width: area.width * 0.4, height: area.height * 0.22))
            leaf.apply(CGAffineTransform(rotationAngle: angle))
            leaf.apply(CGAffineTransform(translationX: leafCenter.x, y: leafCenter.y))
            colors[index % colors.count].setFill()
            leaf.fill()
        }
    }

    /// A big lily pad with a notch.
    private func drawLilyPad(in area: CGRect) {
        let center = CGPoint(x: area.midX, y: area.midY)
        let radius = min(area.width, area.height) / 2
        let pad = UIBezierPath()
        pad.move(to: center)
        pad.addArc(withCenter: center, radius: radius, startAngle: 0.35, endAngle: 2 * .pi - 0.05, clockwise: true)
        pad.close()
        UIColor(red: 0.16, green: 0.42, blue: 0.24, alpha: 1).setFill()
        pad.fill()
        UIColor(red: 0.10, green: 0.32, blue: 0.18, alpha: 1).setStroke()
        for index in 0..<6 {
            let angle = 0.6 + CGFloat(index) * 0.95
            let vein = UIBezierPath()
            vein.move(to: center)
            vein.addLine(to: CGPoint(x: center.x + cos(angle) * radius * 0.85, y: center.y + sin(angle) * radius * 0.85))
            vein.lineWidth = 2
            vein.stroke()
        }
    }

    /// A soft drift of snow.
    private func drawSnowMound(in area: CGRect) {
        UIColor(white: 0.86, alpha: 1).setFill()
        UIBezierPath(ovalIn: area.insetBy(dx: 0, dy: area.height * 0.08)).fill()
        UIColor.white.setFill()
        UIBezierPath(ovalIn: CGRect(x: area.minX + area.width * 0.18, y: area.minY + area.height * 0.18,
                                    width: area.width * 0.45, height: area.height * 0.35)).fill()
    }
}
