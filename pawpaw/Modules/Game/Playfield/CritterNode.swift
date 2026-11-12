//
//  CritterNode.swift
//  pawpaw
//

import SpriteKit
import UIKit

/// One critter on the field. Each nested node runs its own actions, so their movements add up:
/// the path, then heading and startle hop (`turn`), twitches and sways (`jiggle`), wingbeats
/// (`wings`), and body scale and opacity (`sprite`).
final class CritterNode: SKNode {
    /// How far a startled critter hops away from a missed tap, in points,
    /// then how far it recoils back before settling where it started.
    static let startleDistance: CGFloat = 46
    static let startleRecoil: CGFloat = 8

    let sprite = SKSpriteNode()
    private let turn = SKNode()
    private let jiggle = SKNode()
    private let wings = SKNode()
    /// Whether the critter is drawn beneath the hiding spots.
    private(set) var canTakeCover = false
    /// Side of the artwork, without the shadow padding.
    private var artworkSide: CGFloat = 0
    private var caughtArtwork: PlayfieldTextures.Critter?

    override init() {
        super.init()
        addChild(turn)
        turn.addChild(jiggle)
        jiggle.addChild(wings)
        wings.addChild(sprite)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showCaughtGlow() {
        guard let caughtArtwork else { return }
        sprite.texture = caughtArtwork.texture
        sprite.size = caughtArtwork.size
    }

    /// Calls `completion` when the path ends, unless the critter was stopped first.
    /// Sibling order is ignored, so `spawnOrder` puts later critters on top within `layer`.
    func play(
        _ plan: CritterActions.Plan, artwork: PlayfieldTextures.Critter,
        caughtArtwork: PlayfieldTextures.Critter?,
        layer: CGFloat, canTakeCover: Bool, spawnOrder: Int, completion: @escaping () -> Void
    ) {
        self.canTakeCover = canTakeCover
        self.caughtArtwork = caughtArtwork
        artworkSide = artwork.side
        sprite.texture = artwork.texture
        sprite.size = artwork.size
        sprite.alpha = plan.opacity
        zPosition = layer + CGFloat(spawnOrder % 1_000) * 0.001
        position = plan.start
        turn.zRotation = plan.heading
        run(.sequence([plan.path, .run(completion)]))
        if let heading = plan.turn { turn.run(heading) }
        for action in plan.jiggle { jiggle.run(action) }
        for action in plan.wings { wings.run(action) }
        for action in plan.body { sprite.run(action) }
    }

    func stop() {
        let parts: [SKNode] = [self, turn, jiggle, wings, sprite]
        for part in parts { part.removeAllActions() }
        // Open the wings, so the catch squash isn't distorted by a half-finished beat.
        wings.setScale(1)
    }

    /// A hop away from `location`, on top of the path. Replaces any hop in progress.
    func startle(from location: CGPoint, reducesMotion: Bool) {
        turn.removeAction(forKey: "startle")
        turn.position = .zero
        turn.setScale(1)
        let center = center
        let distance = max(hypot(center.x - location.x, center.y - location.y), 1)
        let dx = (center.x - location.x) / distance
        let dy = (center.y - location.y) / distance
        let out = Self.startleDistance
        let recoil = Self.startleRecoil
        let hop = SKAction.sequence([
            .moveBy(x: dx * out, y: dy * out, duration: 0.105),
            .moveBy(x: -dx * recoil, y: -dy * recoil, duration: 0.105),
            .moveBy(x: -dx * (out - recoil), y: -dy * (out - recoil), duration: 0.14),
        ])
        // The hop is how the critter flees, so it stays; only the bounce goes.
        if reducesMotion {
            turn.run(hop, withKey: "startle")
            return
        }
        let squash = SKAction.sequence([
            .scale(to: 1.18, duration: 0.105), .scale(to: 1, duration: 0.245),
        ])
        turn.run(.group([hop, squash]), withKey: "startle")
    }

    var opacity: CGFloat {
        sprite.alpha
    }

    /// Includes the twitch and startle offsets, unlike `position`.
    var center: CGPoint {
        sprite.convert(CGPoint.zero, to: self) + position
    }

    var hitFrame: CGRect {
        let rotation = turn.zRotation + jiggle.zRotation
        let cosine = abs(cos(rotation))
        let sine = abs(sin(rotation))
        let scaleX = abs(sprite.xScale * wings.xScale * turn.xScale)
        let scaleY = abs(sprite.yScale * turn.yScale)
        let width = artworkSide * (scaleX * cosine + scaleY * sine)
        let height = artworkSide * (scaleX * sine + scaleY * cosine)
        let center = center
        return CGRect(
            x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }

    func reset() {
        stop()
        removeFromParent()
        caughtArtwork = nil
        sprite.texture = nil
        for node in [turn, jiggle, wings, sprite] as [SKNode] {
            node.position = .zero
            node.zRotation = 0
            node.setScale(1)
        }
        sprite.alpha = 1
        canTakeCover = false
    }
}

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}
