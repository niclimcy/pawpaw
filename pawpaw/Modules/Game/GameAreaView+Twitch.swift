//
//  GameAreaView+Twitch.swift
//  pawpaw
//

import UIKit

/// Small movements during a freeze. Stillness then a sudden twitch is what makes a cat stalk and pounce.
extension GameAreaView {
    struct Twitch {
        let start: TimeInterval
        let duration: TimeInterval
        /// Rotates; otherwise shuffles in place.
        let jiggles: Bool
    }

    /// 1–3 short twitches at random times in a freeze, with stillness before each one.
    func twitches(from start: TimeInterval, during pause: TimeInterval, style: MovementStyle, turns: Bool) -> [Twitch] {
        let canJiggle = turns && style.twitchAngle > 0
        let canShuffle = style.twitchShift > 0
        guard canJiggle || canShuffle, pause >= 0.25 else { return [] }
        let count = max(1, min(Int.random(in: 1...3), Int(pause / 0.25)))
        let slot = pause / Double(count)
        return (0..<count).map { index in
            let duration = TimeInterval.random(in: 0.1...min(0.25, slot / 2))
            let delay = TimeInterval.random(in: (slot * 0.3)...(slot - duration))
            return Twitch(
                start: start + slot * Double(index) + delay,
                duration: duration,
                jiggles: canJiggle && (!canShuffle || Bool.random())
            )
        }
    }

    /// Additive animations to add after the path's own, so they layer on top of it.
    func twitchAnimations(for twitches: [Twitch], style: MovementStyle, total: TimeInterval) -> [CAKeyframeAnimation] {
        let jiggles = twitches.filter { $0.jiggles }
        let shuffles = twitches.filter { !$0.jiggles }
        var animations: [CAKeyframeAnimation] = []
        if !jiggles.isEmpty {
            animations.append(additiveTwitch(
                keyPath: "transform.rotation.z",
                twitches: jiggles,
                total: total,
                rest: NSNumber(value: 0.0)
            ) {
                let angle = style.twitchAngle * Double.random(in: 0.6...1) * (Bool.random() ? 1 : -1)
                return (NSNumber(value: angle), NSNumber(value: -angle / 2))
            })
        }
        if !shuffles.isEmpty {
            animations.append(additiveTwitch(
                keyPath: "position",
                twitches: shuffles,
                total: total,
                rest: NSValue(cgPoint: .zero)
            ) {
                let direction = CGFloat.random(in: 0..<(2 * .pi))
                let reach = CGFloat(style.twitchShift * Double.random(in: 0.6...1))
                let dx = cos(direction) * reach
                let dy = sin(direction) * reach
                return (NSValue(cgPoint: CGPoint(x: dx, y: dy)), NSValue(cgPoint: CGPoint(x: -dx / 2, y: -dy / 2)))
            })
        }
        return animations
    }

    /// Rests at `rest`, and during each twitch swings out, back past rest, then settles.
    private func additiveTwitch(
        keyPath: String,
        twitches: [Twitch],
        total: TimeInterval,
        rest: Any,
        swing: () -> (Any, Any)
    ) -> CAKeyframeAnimation {
        var values: [Any] = [rest]
        var keyTimes: [NSNumber] = [0]
        for twitch in twitches {
            let (out, back) = swing()
            let keys: [(fraction: Double, value: Any)] = [(0, rest), (1.0 / 3, out), (2.0 / 3, back), (1, rest)]
            for key in keys {
                values.append(key.value)
                keyTimes.append(NSNumber(value: (twitch.start + twitch.duration * key.fraction) / total))
            }
        }
        values.append(rest)
        keyTimes.append(1)

        let animation = CAKeyframeAnimation(keyPath: keyPath)
        animation.isAdditive = true
        animation.values = values
        animation.keyTimes = keyTimes
        animation.calculationMode = .linear
        return animation
    }
}
