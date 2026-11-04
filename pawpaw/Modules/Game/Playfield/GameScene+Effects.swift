//
//  GameScene+Effects.swift
//  pawpaw
//

import SpriteKit
import UIKit

/// Catch, miss and trail effects. All are children of `world`, so they freeze with the round.
extension GameScene {
    static let waterRippleColor = UIColor(red: 0.6, green: 0.85, blue: 1, alpha: 0.6)

    func playCatchEffects(points: Int, at position: CGPoint) {
        emitSparkles(at: position, bigBurst: points >= 20)
        emitRing(at: position, color: Theme.gold, endRadius: 110, lineWidth: 5)
        emitRing(at: position, color: .white, endRadius: 70, lineWidth: 3, delay: 0.06)
        flash(at: position)
        showPoints(points, at: position)
    }

    func playMissEffect(at position: CGPoint) {
        emitRing(at: position, color: Theme.text.withAlphaComponent(0.6), endRadius: 28, lineWidth: 2)
    }

    func playTrailEffect(at position: CGPoint) {
        emitRing(at: position, color: Theme.text.withAlphaComponent(0.35), endRadius: 18, lineWidth: 1.5)
    }

    /// Squash, burst with a spin, then shrink away, from wherever the critter was caught.
    func playCatchAnimation(on critter: CritterNode, completion: @escaping () -> Void) {
        critter.showCaughtGlow()
        let sprite = critter.sprite
        let baseX = sprite.xScale
        let baseY = sprite.yScale
        let squash = SKAction.scaleX(to: baseX * 0.7, y: baseY * 1.3, duration: 0.1)
        squash.timingMode = .easeInEaseOut
        // Negative angles spin clockwise.
        let burst = SKAction.group([
            .scaleX(to: baseX * 1.6, y: baseY * 1.6, duration: 0.14),
            .rotate(toAngle: -.pi / 5, duration: 0.14, shortestUnitArc: false)
        ])
        burst.timingMode = .easeInEaseOut
        let vanish = SKAction.group([
            .scaleX(to: baseX * 0.1, y: baseY * 0.1, duration: 0.16),
            .rotate(toAngle: -.pi, duration: 0.16, shortestUnitArc: false),
            .fadeOut(withDuration: 0.16)
        ])
        vanish.timingMode = .easeInEaseOut
        sprite.run(.sequence([squash, burst, vanish, .run(completion)]))
    }

    /// Scales a cached texture, rather than rebuilding a shape every frame.
    func emitRing(at position: CGPoint, color: UIColor, endRadius: CGFloat, lineWidth: CGFloat, delay: TimeInterval = 0) {
        let ring = SKSpriteNode(texture: PlayfieldTextures.ring(radius: endRadius, lineWidth: lineWidth))
        ring.position = position
        ring.zPosition = Layer.effect
        ring.color = color
        ring.colorBlendFactor = 1
        ring.alpha = 0
        ring.setScale(8 / endRadius)
        world.addChild(ring)
        let grow = SKAction.group([.scale(to: 1, duration: 0.5), .sequence([.fadeAlpha(to: color.cgColor.alpha, duration: 0), .fadeOut(withDuration: 0.5)])])
        grow.timingMode = .easeOut
        ring.run(.sequence([.wait(forDuration: delay), grow, .removeFromParent()]))
    }

    /// Gold and white stars with a few dots, more for the rarer critters.
    private func emitSparkles(at position: CGPoint, bigBurst: Bool) {
        let cells: [(texture: SKTexture, color: UIColor, count: Int, big: Bool)] = [
            (PlayfieldTextures.star, Theme.gold, bigBurst ? 4 : 2, true),
            (PlayfieldTextures.star, .white, bigBurst ? 4 : 2, true),
            (PlayfieldTextures.dot, Theme.gold, bigBurst ? 3 : 1, false)
        ]
        for cell in cells {
            // Bursts `count` particles over 0.08 s.
            let emitter = SKEmitterNode()
            emitter.particleTexture = cell.texture
            emitter.particleColor = cell.color
            emitter.particleColorBlendFactor = 1
            emitter.particleBlendMode = .add
            emitter.particleBirthRate = CGFloat(cell.count) / 0.08
            emitter.numParticlesToEmit = cell.count
            emitter.particleLifetime = 1.0
            emitter.particleLifetimeRange = 0.8
            emitter.particleSpeed = cell.big ? 220 : 140
            emitter.particleSpeedRange = 180
            emitter.emissionAngleRange = .pi * 2
            emitter.yAcceleration = -260
            emitter.particleScale = cell.big ? 0.9 : 0.7
            emitter.particleScaleRange = 0.8
            emitter.particleScaleSpeed = -0.5
            // SpriteKit has no spin range, so every particle spins at the same speed.
            emitter.particleRotationSpeed = 3
            emitter.particleAlphaSpeed = -1.1
            emitter.position = position
            emitter.zPosition = Layer.effect
            world.addChild(emitter)
            emitter.run(.sequence([.wait(forDuration: 1.6), .removeFromParent()]))
        }
    }

    private func flash(at position: CGPoint) {
        let glow = SKSpriteNode(texture: PlayfieldTextures.flash)
        glow.position = position
        glow.zPosition = Layer.effect
        glow.setScale(0.3)
        world.addChild(glow)
        let grow = SKAction.group([.scale(to: 1.4, duration: 0.35), .fadeOut(withDuration: 0.35)])
        grow.timingMode = .easeOut
        glow.run(.sequence([grow, .removeFromParent()]))
    }

    private func showPoints(_ points: Int, at position: CGPoint) {
        let label = SKSpriteNode(texture: PlayfieldTextures.points(points))
        label.position = position
        label.zPosition = Layer.label
        label.setScale(0.4)
        world.addChild(label)

        let springDuration: TimeInterval = 0.25
        let pop = SKAction.customAction(withDuration: springDuration) { node, time in
            let t = Double(time) / springDuration
            let progress = 1 - exp(-6 * t) * cos(3 * .pi * t)
            node.setScale(0.4 + 0.6 * CGFloat(progress))
        }
        let rise = SKAction.group([.moveBy(x: 0, y: 70, duration: 0.8), .fadeOut(withDuration: 0.8)])
        rise.timingMode = .easeOut
        label.run(.group([pop, .sequence([.wait(forDuration: 0.1), rise, .removeFromParent()])]))
    }
}
