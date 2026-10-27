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

        // Critters slide in from beyond the edge instead of fading in.
        var current = offscreenPoint(for: target.start)
        var positions = [NSValue(cgPoint: current)]
        var positionTimes: [NSNumber] = [0]
        var rotations: [NSNumber] = []
        var rotationTimes: [NSNumber] = []

        func addRotation(_ value: CGFloat, at time: TimeInterval) {
            rotations.append(NSNumber(value: Double(value)))
            rotationTimes.append(NSNumber(value: time / total))
        }

        var elapsed: TimeInterval = 0
        var heading: CGFloat = 0
        var previousPause: TimeInterval = 0
        for (index, leg) in target.legs.enumerated() {
            let destination = leg.exits ? offscreenPoint(for: leg.destination) : point(for: leg.destination)
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
                    // Hide by running off the nearest edge, waiting out of sight, then running back.
                    let edge = hideEdgePoint(from: destination)
                    var outHeading = atan2(edge.y - destination.y, edge.x - destination.x) + .pi / 2
                    while outHeading - heading > .pi { outHeading -= 2 * .pi }
                    while outHeading - heading < -.pi { outHeading += 2 * .pi }
                    let returnHeading = outHeading + .pi
                    let hideTravel = MovementPlanner.hideTravel

                    addRotation(outHeading, at: elapsed + 0.1)
                    addRotation(outHeading, at: elapsed + hideTravel)
                    addRotation(returnHeading, at: elapsed + leg.pause - hideTravel)
                    addRotation(returnHeading, at: elapsed + leg.pause - 0.12)
                    positions.append(NSValue(cgPoint: edge))
                    positionTimes.append(NSNumber(value: (elapsed + hideTravel) / total))
                    positions.append(NSValue(cgPoint: edge))
                    positionTimes.append(NSNumber(value: (elapsed + leg.pause - hideTravel) / total))
                    heading = returnHeading
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

        let group = CAAnimationGroup()
        group.animations = [move, turn]
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

    /// A spot just beyond the edge nearest to `point`, where a hiding critter waits out of sight.
    func hideEdgePoint(from point: CGPoint) -> CGPoint {
        let margin = targetSize * 0.75
        let gaps = [point.x, bounds.width - point.x, point.y, bounds.height - point.y]
        switch gaps.firstIndex(of: gaps.min() ?? 0) {
        case 0: return CGPoint(x: -margin, y: point.y)
        case 1: return CGPoint(x: bounds.width + margin, y: point.y)
        case 2: return CGPoint(x: point.x, y: -margin)
        default: return CGPoint(x: point.x, y: bounds.height + margin)
        }
    }

    /// Like `point(for:)`, but a point on the border is pushed far enough out that the critter is fully off-screen.
    func offscreenPoint(for normalized: CGPoint) -> CGPoint {
        var result = point(for: normalized)
        let margin = targetSize * 0.75
        if normalized.x <= 0 { result.x = -margin }
        if normalized.x >= 1 { result.x = bounds.width + margin }
        if normalized.y <= 0 { result.y = -margin }
        if normalized.y >= 1 { result.y = bounds.height + margin }
        return result
    }
}
