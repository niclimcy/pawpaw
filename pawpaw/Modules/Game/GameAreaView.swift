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
    /// Extra reach around a critter so a big paw still counts as a hit.
    private let hitSlop: CGFloat = 28
    /// Distance a dragging paw travels between trail ripples.
    private let trailSpacing: CGFloat = 36
    private var lastRipple: [ObjectIdentifier: CGPoint] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isMultipleTouchEnabled = true
    }

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
        addSubview(label)
        targetViews[target.id] = label
        SoundPlayer.shared.playAppear(for: target.kind)

        animatePath(of: target, on: label) { [weak self, weak label] in
            guard let self, let label, self.targetViews[target.id] === label else { return }
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
        // Keep the heading the critter had when it was caught.
        let heading = label.layer.presentation()?.affineTransform() ?? label.transform
        label.layer.removeAllAnimations()
        label.center = position
        label.transform = heading

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
        SoundPlayer.shared.play(.catchPop)
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
        // Every paw counts: a cat may touch with several toes at once.
        for touch in touches {
            let location = touch.location(in: self)
            lastRipple[ObjectIdentifier(touch)] = location
            if let id = targetID(at: location) {
                onTapTarget?(id)
            } else {
                playMissEffect(at: location)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            // A paw dragged across a critter catches it too.
            if let id = targetID(at: location) {
                onTapTarget?(id)
                continue
            }
            // Leave a trail of small ripples behind a dragging paw.
            let key = ObjectIdentifier(touch)
            let last = lastRipple[key] ?? location
            if hypot(location.x - last.x, location.y - last.y) >= trailSpacing {
                lastRipple[key] = location
                playTrailEffect(at: location)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach { lastRipple[ObjectIdentifier($0)] = nil }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach { lastRipple[ObjectIdentifier($0)] = nil }
    }

    /// The visible critter under `location`, newest (topmost) first.
    private func targetID(at location: CGPoint) -> UUID? {
        let ordered = targetViews.sorted {
            (subviews.firstIndex(of: $0.value) ?? 0) > (subviews.firstIndex(of: $1.value) ?? 0)
        }
        for (id, label) in ordered {
            // Critters hiding under the planks can't be caught.
            guard (label.layer.presentation()?.opacity ?? 1) > 0.5 else { continue }
            let frame = label.layer.presentation()?.frame ?? label.frame
            if frame.insetBy(dx: -hitSlop, dy: -hitSlop).contains(location) {
                return id
            }
        }
        return nil
    }

    // MARK: Layout helpers
    func point(for normalized: CGPoint) -> CGPoint {
        let inset = targetSize / 2 + 8
        let width = max(bounds.width - inset * 2, 0)
        let height = max(bounds.height - inset * 2, 0)
        return CGPoint(x: inset + normalized.x * width, y: inset + normalized.y * height)
    }

}
