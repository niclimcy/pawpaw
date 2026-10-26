//
//  GameAreaView+Rings.swift
//  pawpaw
//

import UIKit

extension GameAreaView {
    func emitRing(at position: CGPoint, color: UIColor, endRadius: CGFloat, lineWidth: CGFloat, delay: CFTimeInterval = 0) {
        let ring = CAShapeLayer()
        ring.path = UIBezierPath(arcCenter: position, radius: 8, startAngle: 0, endAngle: .pi * 2, clockwise: true).cgPath
        ring.fillColor = nil
        ring.strokeColor = color.cgColor
        ring.lineWidth = lineWidth
        ring.shadowColor = color.cgColor
        ring.shadowRadius = 6
        ring.shadowOpacity = 1
        ring.shadowOffset = .zero
        ring.opacity = 0
        layer.addSublayer(ring)

        let grow = CABasicAnimation(keyPath: "path")
        grow.toValue = UIBezierPath(arcCenter: position, radius: endRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true).cgPath
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0
        let group = CAAnimationGroup()
        group.animations = [grow, fade]
        group.duration = 0.5
        group.beginTime = CACurrentMediaTime() + delay
        group.fillMode = .backwards
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        ring.add(group, forKey: "ring")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + delay) { ring.removeFromSuperlayer() }
    }

    func flash(at position: CGPoint) {
        let glow = UIView(frame: CGRect(x: 0, y: 0, width: 160, height: 160))
        glow.center = position
        glow.layer.cornerRadius = 80
        glow.backgroundColor = Theme.gold.withAlphaComponent(0.55)
        glow.layer.shadowColor = Theme.gold.cgColor
        glow.layer.shadowRadius = 30
        glow.layer.shadowOpacity = 1
        glow.layer.shadowOffset = .zero
        glow.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        glow.isUserInteractionEnabled = false
        addSubview(glow)
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut, animations: {
            glow.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
            glow.alpha = 0
        }, completion: { _ in glow.removeFromSuperview() })
    }

    func showPoints(_ points: Int, at position: CGPoint) {
        let label = UILabel()
        label.text = "+\(points)"
        label.font = Theme.roundedFont(size: 34)
        label.textColor = Theme.gold
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOpacity = 0.9
        label.layer.shadowRadius = 3
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.sizeToFit()
        label.center = position
        label.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        addSubview(label)

        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: []) {
            label.transform = .identity
        }
        UIView.animate(withDuration: 0.8, delay: 0.1, options: .curveEaseOut, animations: {
            label.center.y -= 70
            label.alpha = 0
        }, completion: { _ in label.removeFromSuperview() })
    }
}
