//
//  GameScene.swift
//  pawpaw
//

import SpriteKit
import UIKit

/// The play field, drawn over the view controller's background. Everything that moves lives under
/// `world`, so freezing it pauses the round without relying on SpriteKit's own scene pause,
/// which it lifts by itself when the app returns.
final class GameScene: SKScene {
    /// Draw order, as `zPosition`s. Critters that can hide go beneath the spots; the rest pass over them.
    enum Layer {
        static let coveredCritter: CGFloat = 10
        static let hidingSpot: CGFloat = 20
        static let critter: CGFloat = 30
        static let effect: CGFloat = 40
        static let label: CGFloat = 50
    }

    var onTapTarget: ((UUID) -> Void)?
    var onExpire: ((UUID) -> Void)?
    /// The scene removed the critter itself (on resize or missing artwork); neither caught nor escaped.
    var onDiscard: ((UUID) -> Void)?
    var onMiss: (() -> Void)?
    var onTapLure: (() -> Void)?
    /// The lure's loop ended at this normalized point.
    var onLureLoopEnd: ((CGPoint) -> Void)?
    /// A relayout removed the lure; it needs a new cover and path.
    var onLureDiscard: (() -> Void)?
    /// Any touch on the field, so the view knows someone is still playing.
    var onTouch: (() -> Void)?
    var theme: PlayfieldTheme = .wood
    var tuning: PlayfieldTuning = .standard
    /// Height of the strip under the HUD. Critters run through it on their way off-screen,
    /// but never spawn, stop or hide in it.
    var topInset: CGFloat = 0 {
        didSet {
            guard topInset != oldValue else { return }
            relayout()
        }
    }

    let world = SKNode()
    private var hidingSpotNodes: [SKSpriteNode] = []
    private var hidingSpotPoints: [CGPoint] = []
    private var laidOutSize: CGSize = .zero
    private var laidOutTopInset: CGFloat = 0
    private var targetNodes: [UUID: CritterNode] = [:]
    private var recycledNodes: [CritterNode] = []
    private var spawnCount = 0
    private var hitSlop: CGFloat {
        tuning.hitSlop
    }
    /// More generous than in a round: the lure is there to be caught.
    private var lureHitSlop: CGFloat {
        tuning.lureHitSlop
    }
    private let trailSpacing: CGFloat = 36
    private var startleRange: CGFloat {
        tuning.startleRange
    }
    private var lastRipple: [ObjectIdentifier: CGPoint] = [:]
    /// The critter roaming the results between rounds; kept apart from the round's critters.
    private var lureNode: CritterNode?
    /// Scene rect of the results card. The lure can't be caught while its center is behind it.
    private var lureObstacle: CGRect?
    /// Scene point of the latest touch, roughly where the cat is.
    private var lastTouch: CGPoint?

    private var geometry: PlayfieldGeometry {
        PlayfieldGeometry(size: size, topInset: topInset, tuning: tuning)
    }

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = .zero
        backgroundColor = .clear
        isUserInteractionEnabled = true
        addChild(world)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        relayout()
    }

    /// On resize or a new HUD inset, hiding spots are repositioned. Running paths can't be rescaled,
    /// so those critters are discarded.
    private func relayout() {
        guard size != laidOutSize || topInset != laidOutTopInset, size.width > 0, size.height > 0 else { return }
        let hadLayout = laidOutSize != .zero
        laidOutSize = size
        laidOutTopInset = topInset
        placeHidingSpots()
        guard hadLayout else { return }
        for (id, critter) in targetNodes {
            targetNodes[id] = nil
            recycle(critter)
            onDiscard?(id)
        }
        if lureNode != nil {
            removeLure()
            onLureDiscard?()
        }
    }

    // MARK: Critters

    func add(_ target: GameTarget) {
        guard let plan = CritterActions.plan(for: target, in: geometry),
              let artwork = PlayfieldTextures.critter(target.kind, variant: target.variant, size: tuning.targetSize) else {
            onDiscard?(target.id)
            return
        }
        let critter = recycledNodes.popLast() ?? CritterNode()
        let canTakeCover = !hidingSpotNodes.isEmpty && theme.allowsCover(for: target.kind.movementStyle)
        spawnCount += 1
        world.addChild(critter)
        targetNodes[target.id] = critter
        critter.play(
            plan,
            artwork: artwork,
            caughtArtwork: PlayfieldTextures.critter(target.kind, variant: target.variant, size: tuning.targetSize, style: .caught),
            layer: canTakeCover ? Layer.coveredCritter : Layer.critter,
            canTakeCover: canTakeCover,
            spawnOrder: spawnCount
        ) { [weak self, weak critter] in
            guard let self, let critter, self.targetNodes[target.id] === critter else { return }
            self.targetNodes[target.id] = nil
            self.recycle(critter)
            self.onExpire?(target.id)
        }
        SoundPlayer.shared.playAppear(for: target.kind, pan: geometry.pan(atX: plan.start.x))
        if target.kind.movementStyle.surfaces {
            emitRing(at: plan.start, color: Self.waterRippleColor, endRadius: 70, lineWidth: 2)
        }
    }

    func caught(id: UUID, points: Int) {
        guard let critter = targetNodes.removeValue(forKey: id) else { return }
        critter.stop()
        let position = critter.center
        playCatchAnimation(on: critter) { [weak self, weak critter] in
            guard let critter else { return }
            self?.recycle(critter)
        }
        playCatchEffects(points: points, at: position)
        SoundPlayer.shared.play(.catchPop, pan: geometry.pan(atX: position.x))
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func removeAllTargets() {
        targetNodes.values.forEach { recycle($0) }
        targetNodes.removeAll()
        removeLure()
    }

    // MARK: Lure

    var hasLure: Bool {
        lureNode != nil
    }

    /// The lure is wandering off; it can still be caught on the way out.
    private(set) var isLureLeaving = false

    /// Normalized position of the lure, for planning its next move.
    var lureNormalizedPosition: CGPoint? {
        lureNode.map { geometry.normalized(for: $0.center) }
    }

    /// Normalized position of the latest touch, roughly where the cat is.
    var lastTouchNormalized: CGPoint? {
        lastTouch.map { geometry.normalized(for: $0) }
    }

    /// Makes `rect` (in the view's coordinates) the lure's cover.
    func setLureObstacle(viewRect rect: CGRect) -> LureCover {
        let corners = [CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.maxY)]
            .map { convertPoint(fromView: $0) }
        let sceneRect = CGRect(
            x: min(corners[0].x, corners[1].x), y: min(corners[0].y, corners[1].y),
            width: abs(corners[1].x - corners[0].x), height: abs(corners[1].y - corners[0].y)
        )
        lureObstacle = sceneRect
        return geometry.lureCover(for: sceneRect)
    }

    /// Plays one loop of the lure. The same node carries on between loops; a leaving lure is removed when it's gone.
    func showLure(_ target: GameTarget, isLeaving: Bool) {
        guard let plan = CritterActions.plan(for: target, in: geometry),
              let artwork = PlayfieldTextures.critter(target.kind, variant: target.variant, size: tuning.targetSize) else {
            removeLure()
            if !isLeaving { onLureDiscard?() }
            return
        }
        isLureLeaving = isLeaving
        let isNew = lureNode == nil
        let critter = lureNode ?? recycledNodes.popLast() ?? CritterNode()
        if isNew {
            world.addChild(critter)
            lureNode = critter
        } else {
            critter.stop()
        }
        spawnCount += 1
        critter.play(
            plan,
            artwork: artwork,
            caughtArtwork: PlayfieldTextures.critter(target.kind, variant: target.variant, size: tuning.targetSize, style: .caught),
            layer: Layer.critter,
            canTakeCover: false,
            spawnOrder: spawnCount
        ) { [weak self, weak critter] in
            guard let self, let critter, self.lureNode === critter else { return }
            if isLeaving {
                self.removeLure()
            } else {
                self.onLureLoopEnd?(self.geometry.normalized(for: critter.position))
            }
        }
        if isNew {
            SoundPlayer.shared.playAppear(for: target.kind, pan: geometry.pan(atX: plan.start.x))
        }
    }

    /// Catch effects without points: the lure isn't scored.
    func catchLure() {
        guard let critter = lureNode else { return }
        lureNode = nil
        isLureLeaving = false
        critter.stop()
        let position = critter.center
        playCatchAnimation(on: critter) { [weak self, weak critter] in
            guard let critter else { return }
            self?.recycle(critter)
        }
        playCatchEffects(points: nil, at: position)
        SoundPlayer.shared.play(.catchPop, pan: geometry.pan(atX: position.x))
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func removeLure() {
        isLureLeaving = false
        guard let critter = lureNode else { return }
        lureNode = nil
        recycle(critter)
    }

    /// Hidden behind the results card, the lure can't be caught, like a critter under a hiding spot.
    private func isLureCatchable(_ critter: CritterNode) -> Bool {
        guard critter.opacity > 0.5, geometry.bounds.intersects(critter.hitFrame) else { return false }
        return !(lureObstacle?.contains(critter.center) ?? false)
    }

    private func lureHit(at location: CGPoint) -> Bool {
        guard let critter = lureNode, isLureCatchable(critter) else { return false }
        return critter.hitFrame.insetBy(dx: -lureHitSlop, dy: -lureHitSlop).contains(location)
    }

    func freeze() {
        world.isPaused = true
        lastRipple.removeAll()
    }

    func resume() {
        world.isPaused = false
    }

    private func recycle(_ critter: CritterNode) {
        critter.reset()
        recycledNodes.append(critter)
    }

    // MARK: Hiding spots

    /// Normalized (0...1) centers.
    func showHidingSpots(at points: [CGPoint]) {
        hidingSpotNodes.forEach { $0.removeFromParent() }
        hidingSpotPoints = points
        let texture = PlayfieldTextures.hidingSpot(for: theme, side: tuning.hidingSpotSize)
        hidingSpotNodes = points.map { _ in
            let spot = SKSpriteNode(texture: texture)
            spot.zPosition = Layer.hidingSpot
            world.addChild(spot)
            return spot
        }
        placeHidingSpots()
    }

    private func placeHidingSpots() {
        for (spot, normalized) in zip(hidingSpotNodes, hidingSpotPoints) {
            spot.position = geometry.point(for: normalized)
        }
    }

    /// Only critters drawn beneath the spots can be hidden by them.
    private func isUnderCover(_ critter: CritterNode) -> Bool {
        guard critter.canTakeCover else { return false }
        let center = critter.center
        return hidingSpotNodes.contains { spot in
            hypot(spot.position.x - center.x, spot.position.y - center.y) < tuning.hidingSpotSize * 0.3
        }
    }

    // MARK: Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !world.isPaused else { return }
        onTouch?()
        for touch in touches {
            let location = touch.location(in: self)
            lastRipple[ObjectIdentifier(touch)] = location
            lastTouch = location
            if lureHit(at: location) {
                onTapLure?()
            } else if let id = targetID(at: location) {
                onTapTarget?(id)
            } else {
                onMiss?()
                playMissEffect(at: location)
                startleNearestTarget(from: location)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !world.isPaused else { return }
        for touch in touches {
            let location = touch.location(in: self)
            lastTouch = location
            if lureHit(at: location) {
                onTapLure?()
                continue
            }
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

    /// Makes the nearest critter hop away from a missed tap.
    private func startleNearestTarget(from location: CGPoint) {
        var candidates = targetNodes.values.compactMap { critter -> (CritterNode, CGFloat)? in
            guard isCatchable(critter) else { return nil }
            let distance = hypot(critter.center.x - location.x, critter.center.y - location.y)
            return distance <= startleRange ? (critter, distance) : nil
        }
        if let lure = lureNode, isLureCatchable(lure) {
            let distance = hypot(lure.center.x - location.x, lure.center.y - location.y)
            if distance <= startleRange { candidates.append((lure, distance)) }
        }
        guard let critter = candidates.min(by: { $0.1 < $1.1 })?.0 else { return }
        critter.startle(from: location)
        SoundPlayer.shared.play(.squeak, pan: geometry.pan(atX: critter.center.x))
    }

    /// Topmost visible critter first.
    private func targetID(at location: CGPoint) -> UUID? {
        targetNodes.sorted { $0.value.zPosition > $1.value.zPosition }.first { _, critter in
            isCatchable(critter) && critter.hitFrame.insetBy(dx: -hitSlop, dy: -hitSlop).contains(location)
        }?.key
    }

    private func isCatchable(_ critter: CritterNode) -> Bool {
        critter.opacity > 0.5 && geometry.bounds.intersects(critter.hitFrame) && !isUnderCover(critter)
    }
}
