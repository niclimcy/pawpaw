//
//  GameAreaView+Movement.swift
//  pawpaw
//

import UIKit

/// Stop-and-go movement: one keyframe animation drives both position and heading.
extension GameAreaView {
    /// Moves `label` along the target's legs, freezing between them, and calls `completion` when done or cancelled.
    func animatePath(of target: GameTarget, on label: UIView, completion: @escaping () -> Void) {
        let total = target.lifetime
        guard total > 0, !target.legs.isEmpty else {
            completion()
            return
        }

        var current = point(for: target.start)
        var positions = [NSValue(cgPoint: current)]
        var positionTimes: [NSNumber] = [0]
        var rotations: [NSNumber] = []
        var rotationTimes: [NSNumber] = []

        // Opacity: fade in on arrival, and vanish during hiding freezes.
        let fade: TimeInterval = 0.2
        var opacities: [NSNumber] = [0, 1]
        var opacityTimes: [NSNumber] = [0, NSNumber(value: min(0.4, total) / total)]
        func addOpacity(_ value: Double, at time: TimeInterval) {
            let last = opacityTimes.last?.doubleValue ?? 0
            opacities.append(NSNumber(value: value))
            opacityTimes.append(NSNumber(value: max(last, min(time / total, 1))))
        }

        var elapsed: TimeInterval = 0
        var heading: CGFloat = 0
        var previousPause: TimeInterval = 0
        for (index, leg) in target.legs.enumerated() {
            let destination = point(for: leg.destination)
            // The artwork faces up, so turn it to face the direction of travel.
            var legHeading = atan2(destination.y - current.y, destination.x - current.x) + .pi / 2
            if index > 0 {
                // Take the short way round.
                while legHeading - heading > .pi { legHeading -= 2 * .pi }
                while legHeading - heading < -.pi { legHeading += 2 * .pi }
            }
            heading = legHeading

            // Frozen critters turn on the spot; continuous movers curve into the next heading.
            if index == 0 || previousPause > 0 {
                rotations.append(NSNumber(value: Double(heading)))
                rotationTimes.append(NSNumber(value: elapsed / total))
            }
            elapsed += leg.travel
            rotations.append(NSNumber(value: Double(heading)))
            rotationTimes.append(NSNumber(value: elapsed / total))
            positions.append(NSValue(cgPoint: destination))
            positionTimes.append(NSNumber(value: elapsed / total))

            if leg.pause > 0 {
                if leg.hides {
                    addOpacity(1, at: elapsed)
                    addOpacity(0, at: elapsed + fade)
                    addOpacity(0, at: elapsed + leg.pause - fade)
                    addOpacity(1, at: elapsed + leg.pause)
                }
                elapsed += leg.pause
                positions.append(NSValue(cgPoint: destination))
                positionTimes.append(NSNumber(value: elapsed / total))
            }
            previousPause = leg.pause
            current = destination
        }
        // Rounding must not leave the last key short of the end.
        positionTimes[positionTimes.count - 1] = 1
        rotationTimes[rotationTimes.count - 1] = 1

        let move = CAKeyframeAnimation(keyPath: "position")
        move.values = positions
        move.keyTimes = positionTimes
        move.calculationMode = .linear

        let turn = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        turn.values = rotations
        turn.keyTimes = rotationTimes
        turn.calculationMode = .linear

        addOpacity(1, at: total)
        let appear = CAKeyframeAnimation(keyPath: "opacity")
        appear.values = opacities
        appear.keyTimes = opacityTimes
        appear.calculationMode = .linear

        let group = CAAnimationGroup()
        group.animations = [move, turn, appear]
        group.duration = total

        // Model values describe the end state; the animation shows the journey.
        label.transform = CGAffineTransform(rotationAngle: heading)
        label.center = current
        label.alpha = 1

        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        label.layer.add(group, forKey: "path")
        CATransaction.commit()
    }
}
