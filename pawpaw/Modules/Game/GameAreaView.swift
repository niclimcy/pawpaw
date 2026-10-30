//
//  GameAreaView.swift
//  pawpaw
//

import UIKit

/// Taps are matched against each critter's presentation frame, since critters are mid-animation.
final class GameAreaView: UIView {
    var onTapTarget: ((UUID) -> Void)?
    var onExpire: ((UUID) -> Void)?
    /// The view removed the critter itself (on resize); neither caught nor escaped.
    var onDiscard: ((UUID) -> Void)?
    var onMiss: (() -> Void)?

    var theme: PlayfieldTheme = .wood
    let hidingSpotSize: CGFloat = 170
    private var hidingSpotViews: [HidingSpotView] = []
    private var hidingSpotPoints: [CGPoint] = []
    private var laidOutSize: CGSize = .zero
    private var targetViews: [UUID: UIImageView] = [:]
    private var recycledViews: [UIImageView] = []
    let targetSize: CGFloat = 126
    private let hitSlop: CGFloat = 28
    private let trailSpacing: CGFloat = 36
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

    /// On resize, hiding spots are repositioned. Running paths can't be rescaled, so those critters are discarded.
    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != laidOutSize else { return }
        let hadLayout = laidOutSize != .zero
        laidOutSize = bounds.size
        placeHidingSpots()
        guard hadLayout else { return }
        for (id, critter) in targetViews {
            targetViews[id] = nil
            recycle(critter)
            onDiscard?(id)
        }
    }

    func add(_ target: GameTarget) {
        let critter = dequeueTargetView()
        critter.image = UIImage(named: target.kind.imageName)
        if target.kind.glows {
            critter.layer.shadowColor = UIColor.red.cgColor
            critter.layer.shadowRadius = 14
            critter.layer.shadowOpacity = 0.9
            critter.layer.shadowOffset = .zero
        }
        let surfaces = target.kind.movementStyle.surfaces
        if surfaces {
            critter.layer.shadowColor = UIColor(red: 0, green: 0.05, blue: 0.15, alpha: 1).cgColor
            critter.layer.shadowRadius = 10
            critter.layer.shadowOpacity = 0.5
            critter.layer.shadowOffset = .zero
            critter.alpha = 0
        }
        critter.center = surfaces ? point(for: target.start) : offscreenPoint(for: target.start)
        // Critters that can take cover go beneath the spots; the rest pass over them.
        if let lowestSpot = hidingSpotViews.first, theme.allowsCover(for: target.kind.movementStyle) {
            insertSubview(critter, belowSubview: lowestSpot)
        } else {
            addSubview(critter)
        }
        targetViews[target.id] = critter
        SoundPlayer.shared.playAppear(for: target.kind)

        animatePath(of: target, on: critter) { [weak self, weak critter] in
            guard let self, let critter, self.targetViews[target.id] === critter else { return }
            self.targetViews[target.id] = nil
            self.recycle(critter)
            self.onExpire?(target.id)
        }
    }

    private func dequeueTargetView() -> UIImageView {
        let critter = recycledViews.popLast() ?? UIImageView()
        // Reset the transform before setting the frame, or the bounds get distorted.
        critter.transform = .identity
        critter.frame = CGRect(origin: .zero, size: CGSize(width: targetSize, height: targetSize))
        critter.contentMode = .scaleAspectFit
        critter.isUserInteractionEnabled = false
        critter.alpha = 1
        critter.isHidden = false
        critter.layer.shadowColor = UIColor.black.cgColor
        critter.layer.shadowRadius = 6
        critter.layer.shadowOpacity = 0.6
        critter.layer.shadowOffset = CGSize(width: 0, height: 4)
        return critter
    }

    private func recycle(_ critter: UIImageView) {
        critter.layer.removeAllAnimations()
        critter.removeFromSuperview()
        critter.transform = .identity
        critter.image = nil
        recycledViews.append(critter)
    }

    private func isOnScreen(_ critter: UIView) -> Bool {
        let frame = critter.layer.presentation()?.frame ?? critter.frame
        return bounds.intersects(frame) && !isUnderCover(critter, frame: frame)
    }

    /// Only critters layered below the spots can be hidden by them.
    private func isUnderCover(_ critter: UIView, frame: CGRect) -> Bool {
        guard let lowestSpot = hidingSpotViews.first,
              let critterIndex = subviews.firstIndex(of: critter),
              let spotIndex = subviews.firstIndex(of: lowestSpot),
              critterIndex < spotIndex else { return false }
        let center = CGPoint(x: frame.midX, y: frame.midY)
        return hidingSpotViews.contains { spot in
            hypot(spot.center.x - center.x, spot.center.y - center.y) < hidingSpotSize * 0.3
        }
    }

    func showHidingSpots(at points: [CGPoint]) {
        hidingSpotViews.forEach { $0.removeFromSuperview() }
        hidingSpotPoints = points
        hidingSpotViews = points.map { _ in
            let spot = HidingSpotView(theme: theme)
            spot.frame = CGRect(x: 0, y: 0, width: hidingSpotSize, height: hidingSpotSize)
            addSubview(spot)
            return spot
        }
        placeHidingSpots()
    }

    private func placeHidingSpots() {
        for (spot, normalized) in zip(hidingSpotViews, hidingSpotPoints) {
            spot.center = point(for: normalized)
        }
    }

    func caught(id: UUID, points: Int) {
        guard let critter = targetViews.removeValue(forKey: id) else { return }
        let position = critter.layer.presentation()?.position ?? critter.center
        let heading = critter.layer.presentation()?.affineTransform() ?? critter.transform
        critter.layer.removeAllAnimations()
        critter.center = position
        critter.transform = heading

        critter.layer.shadowColor = Theme.gold.cgColor
        critter.layer.shadowRadius = 18
        critter.layer.shadowOpacity = 1
        critter.layer.shadowOffset = .zero
        let base = critter.transform
        UIView.animateKeyframes(withDuration: 0.4, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.25) {
                critter.transform = base.scaledBy(x: 0.7, y: 1.3)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.35) {
                critter.transform = base.scaledBy(x: 1.6, y: 1.6).rotated(by: .pi / 5)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                critter.transform = base.scaledBy(x: 0.1, y: 0.1).rotated(by: .pi)
                critter.alpha = 0
            }
        }, completion: { [weak self] _ in
            self?.recycle(critter)
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
        for touch in touches {
            let location = touch.location(in: self)
            lastRipple[ObjectIdentifier(touch)] = location
            if let id = targetID(at: location) {
                onTapTarget?(id)
            } else {
                onMiss?()
                playMissEffect(at: location)
                startleNearestTarget(from: location, critter: nearestTargetView(to: location))
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if let id = targetID(at: location) {
                onTapTarget?(id)
                continue
            }
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

    private func nearestTargetView(to location: CGPoint) -> UIView? {
        let candidates = targetViews.values.compactMap { critter -> (UIView, CGFloat)? in
            guard let presentation = critter.layer.presentation(), presentation.opacity > 0.5, isOnScreen(critter) else { return nil }
            let distance = hypot(presentation.position.x - location.x, presentation.position.y - location.y)
            return distance <= startleRange ? (critter, distance) : nil
        }
        return candidates.min { $0.1 < $1.1 }?.0
    }

    /// Topmost visible critter first.
    private func targetID(at location: CGPoint) -> UUID? {
        let ordered = targetViews.sorted {
            (subviews.firstIndex(of: $0.value) ?? 0) > (subviews.firstIndex(of: $1.value) ?? 0)
        }
        for (id, critter) in ordered {
            guard (critter.layer.presentation()?.opacity ?? 1) > 0.5, isOnScreen(critter) else { continue }
            let frame = critter.layer.presentation()?.frame ?? critter.frame
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
