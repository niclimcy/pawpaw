//
//  CritterActions+Twitch.swift
//  pawpaw
//

import SpriteKit

extension CritterActions {
    /// 1–3 short twitches at random times in a freeze, with stillness before each: a swing out,
    /// back past rest, then settle. Stillness then a sudden twitch is what makes a cat stalk and pounce.
    static func twitches(during pause: TimeInterval, style: MovementStyle, turns: Bool) -> [(start: TimeInterval, action: SKAction)] {
        let canJiggle = turns && style.twitchAngle > 0
        let canShuffle = style.twitchShift > 0
        guard canJiggle || canShuffle, pause >= 0.25 else { return [] }
        let count = max(1, min(Int.random(in: 1...3), Int(pause / 0.25)))
        let slot = pause / Double(count)
        let shape: [CGFloat] = [1, -1.5, 0.5]
        return (0..<count).map { index in
            let duration = TimeInterval.random(in: 0.1...min(0.25, slot / 2))
            let delay = TimeInterval.random(in: (slot * 0.3)...(slot - duration))
            let step = duration / 3
            let steps: [SKAction]
            if canJiggle && (!canShuffle || Bool.random()) {
                let angle = CGFloat(style.twitchAngle * Double.random(in: 0.6...1) * (Bool.random() ? 1 : -1))
                steps = shape.map { .rotate(byAngle: angle * $0, duration: step) }
            } else {
                let direction = CGFloat.random(in: 0..<(2 * .pi))
                let reach = CGFloat(style.twitchShift * Double.random(in: 0.6...1))
                steps = shape.map { .moveBy(x: cos(direction) * reach * $0, y: sin(direction) * reach * $0, duration: step) }
            }
            return (slot * Double(index) + delay, SKAction.sequence(steps))
        }
    }

    /// Turns `amount` one way, then the other, then back to rest.
    static func swing(_ amount: CGFloat, period: TimeInterval, eased: Bool) -> SKAction {
        let steps = [amount, -2 * amount, amount].map { SKAction.rotate(byAngle: $0, duration: period * TimeInterval(abs($0 / amount)) / 4) }
        if eased { steps.forEach { $0.timingMode = .easeInEaseOut } }
        return .sequence(steps)
    }

    /// Scales the node to 1 plus each of `values`, evenly spaced over `period`.
    /// `scaleX(by:y:)` can't do this: it adds to the scale rather than multiplying it.
    static func pulse(_ values: [CGFloat], period: TimeInterval, eased: Bool, xOnly: Bool = false) -> SKAction {
        .customAction(withDuration: period) { node, elapsed in
            let position = min(max(Double(elapsed) / max(period, .ulpOfOne), 0), 1) * Double(values.count - 1)
            let index = min(Int(position), values.count - 2)
            var t = CGFloat(position) - CGFloat(index)
            // Smoothstep, close to `easeInEaseOut` in each segment.
            if eased { t = t * t * (3 - 2 * t) }
            let scale = 1 + values[index] + (values[index + 1] - values[index]) * t
            if xOnly { node.xScale = scale } else { node.setScale(scale) }
        }
    }
}

/// Actions placed at times since the path started, played as one sequence.
struct Timeline {
    private var actions: [SKAction] = []
    private var cursor: TimeInterval = 0

    var sequence: SKAction {
        .sequence(actions)
    }

    /// Runs `action` at `time`, or straight after the previous one if that's still going.
    mutating func add(_ action: SKAction, at time: TimeInterval) {
        if time > cursor {
            actions.append(.wait(forDuration: time - cursor))
        }
        actions.append(action)
        cursor = max(time, cursor) + action.duration
    }

    /// Animates from the previous key to this one, like a keyframe at `time`.
    mutating func key(at time: TimeInterval, _ action: (TimeInterval) -> SKAction) {
        actions.append(action(max(time - cursor, 0)))
        cursor = max(time, cursor)
    }
}
