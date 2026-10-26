//
//  GameAreaView.swift
//  pawpaw
//

import UIKit

/// The play field. Targets animate across it, so taps are matched against each
/// target's *presentation* (on-screen) frame instead of its final model frame.
final class GameAreaView: UIView {
    var onTapTarget: ((UUID) -> Void)?

    private var targetViews: [UUID: UIImageView] = [:]
    private let targetSize: CGFloat = 126

    func add(_ target: GameTarget) {
        let label = UIImageView(image: UIImage(named: target.kind.imageName))
        label.frame = CGRect(origin: .zero, size: CGSize(width: targetSize, height: targetSize))
        label.contentMode = .scaleAspectFit
        label.isUserInteractionEnabled = false
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 6
        label.layer.shadowOpacity = 0.6
        label.layer.shadowOffset = CGSize(width: 0, height: 4)
        label.center = point(for: target.start)
        label.alpha = 0
        addSubview(label)
        targetViews[target.id] = label

        let destination = point(for: target.end)
        // The artwork faces up, so turn it to face the direction of travel.
        let heading = atan2(destination.y - label.center.y, destination.x - label.center.x) + .pi / 2
        label.transform = CGAffineTransform(rotationAngle: heading)
        UIView.animate(withDuration: 0.6) { label.alpha = 1 }
        UIView.animate(withDuration: target.lifetime, delay: 0, options: [.curveLinear, .allowUserInteraction]) {
            label.center = destination
        } completion: { [weak self, weak label] finished in
            guard finished, let self, let label, self.targetViews[target.id] === label else { return }
            self.targetViews[target.id] = nil
            self.onExpire?(target.id)
            UIView.animate(withDuration: 0.6, animations: { label.alpha = 0 }, completion: { _ in
                label.removeFromSuperview()
            })
        }
    }

    var onExpire: ((UUID) -> Void)?

    func caught(id: UUID, points: Int) {
        guard let label = targetViews.removeValue(forKey: id) else { return }
        let position = label.layer.presentation()?.position ?? label.center
        label.layer.removeAllAnimations()
        label.center = position

        // Glow, then a bouncy squash-and-stretch and a spinning pop out.
        label.layer.shadowColor = Theme.gold.cgColor
        label.layer.shadowRadius = 18
        label.layer.shadowOpacity = 1
        label.layer.shadowOffset = .zero
        let base = label.transform
        UIView.animateKeyframes(withDuration: 0.4, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.25) {
                label.transform = base.scaledBy(x: 0.7, y: 1.3)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.35) {
                label.transform = base.scaledBy(x: 1.6, y: 1.6).rotated(by: .pi / 5)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                label.transform = base.scaledBy(x: 0.1, y: 0.1).rotated(by: .pi)
                label.alpha = 0
            }
        }, completion: { _ in
            label.removeFromSuperview()
        })
        playCatchEffects(points: points, at: position)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func removeAllTargets() {
        targetViews.values.forEach {
            $0.layer.removeAllAnimations()
            $0.removeFromSuperview()
        }
        targetViews.removeAll()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        // Newest targets are on top, so check them first. Hit area is a bit generous for big paws.
        for (id, label) in targetViews.sorted(by: { subviews.firstIndex(of: $0.value) ?? 0 > subviews.firstIndex(of: $1.value) ?? 0 }) {
            let frame = label.layer.presentation()?.frame ?? label.frame
            if frame.insetBy(dx: -12, dy: -12).contains(location) {
                onTapTarget?(id)
                return
            }
        }
        playMissEffect(at: location)
    }

    // MARK: Private
    private func point(for normalized: CGPoint) -> CGPoint {
        let inset = targetSize / 2 + 8
        let width = max(bounds.width - inset * 2, 0)
        let height = max(bounds.height - inset * 2, 0)
        return CGPoint(x: inset + normalized.x * width, y: inset + normalized.y * height)
    }

}
