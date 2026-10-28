//
//  GameAreaView.swift
//  pawpaw
//

import UIKit

/// The play field. Targets animate across it, so taps are matched against each
/// target's *presentation* (on-screen) frame instead of its final model frame.
final class GameAreaView: UIView {
    var onTapTarget: ((UUID) -> Void)?
    /// A touch that started on empty space (drags across empty space don't count).
    var onMiss: (() -> Void)?

    private var targetViews: [UUID: UIImageView] = [:]
    /// Views of critters that left the screen or were caught, kept for the next spawn.
    private var recycledViews: [UIImageView] = []
    let targetSize: CGFloat = 126
    /// Extra reach around a critter so a big paw still counts as a hit.
    private let hitSlop: CGFloat = 28
    /// Distance a dragging paw travels between trail ripples.
    private let trailSpacing: CGFloat = 36
    /// How close a missed tap must land to make a critter jump.
    private let startleRange: CGFloat = 220
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
        let label = dequeueTargetView()
        label.image = UIImage(named: target.kind.imageName)
        if target.kind.glows {
            // Light on the surface glows instead of casting a shadow.
            label.layer.shadowColor = UIColor.red.cgColor
            label.layer.shadowRadius = 14
            label.layer.shadowOpacity = 0.9
            label.layer.shadowOffset = .zero
        }
        label.center = offscreenPoint(for: target.start)
        addSubview(label)
        targetViews[target.id] = label
        SoundPlayer.shared.playAppear(for: target.kind)

        animatePath(of: target, on: label) { [weak self, weak label] in
            guard let self, let label, self.targetViews[target.id] === label else { return }
            // The critter has run off the edge: free its slot and keep the view for the next one.
            self.targetViews[target.id] = nil
            self.recycle(label)
            self.onExpire?(target.id)
        }
    }

    /// A reset critter view, reused from an earlier critter when one is available.
    private func dequeueTargetView() -> UIImageView {
        let label = recycledViews.popLast() ?? UIImageView()
        // Reset the transform first: setting a frame on a rotated or scaled view distorts its bounds.
        label.transform = .identity
        label.frame = CGRect(origin: .zero, size: CGSize(width: targetSize, height: targetSize))
        label.contentMode = .scaleAspectFit
        label.isUserInteractionEnabled = false
        label.alpha = 1
        label.isHidden = false
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 6
        label.layer.shadowOpacity = 0.6
        label.layer.shadowOffset = CGSize(width: 0, height: 4)
        return label
    }

    /// Takes a critter view off the field, wipes its animations and stores it for reuse.
    private func recycle(_ label: UIImageView) {
        label.layer.removeAllAnimations()
        label.removeFromSuperview()
        label.transform = .identity
        label.image = nil
        recycledViews.append(label)
    }

    /// Whether any part of the critter is currently inside the play field.
    private func isOnScreen(_ label: UIView) -> Bool {
        let frame = label.layer.presentation()?.frame ?? label.frame
        return bounds.intersects(frame)
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
        }, completion: { [weak self] _ in
            self?.recycle(label)
        })
        playCatchEffects(points: points, at: position)
        SoundPlayer.shared.play(.catchPop)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func removeAllTargets() {
        targetViews.values.forEach { recycle($0) }
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
                onMiss?()
                playMissEffect(at: location)
                startleNearestTarget(from: location, label: nearestTargetView(to: location))
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

    /// The closest visible critter within startle range of a missed tap.
    private func nearestTargetView(to location: CGPoint) -> UIView? {
        let candidates = targetViews.values.compactMap { label -> (UIView, CGFloat)? in
            guard let presentation = label.layer.presentation(), presentation.opacity > 0.5, isOnScreen(label) else { return nil }
            let distance = hypot(presentation.position.x - location.x, presentation.position.y - location.y)
            return distance <= startleRange ? (label, distance) : nil
        }
        return candidates.min { $0.1 < $1.1 }?.0
    }

    /// The visible critter under `location`, newest (topmost) first.
    private func targetID(at location: CGPoint) -> UUID? {
        let ordered = targetViews.sorted {
            (subviews.firstIndex(of: $0.value) ?? 0) > (subviews.firstIndex(of: $1.value) ?? 0)
        }
        for (id, label) in ordered {
            // Critters hiding under the planks can't be caught.
            guard (label.layer.presentation()?.opacity ?? 1) > 0.5, isOnScreen(label) else { continue }
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
