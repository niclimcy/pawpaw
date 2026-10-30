//
//  GameAreaView+Movement.swift
//  pawpaw
//

import UIKit

extension GameAreaView {
    /// `completion` runs when the path finishes or is cancelled.
    func animatePath(of target: GameTarget, on critter: UIView, completion: @escaping () -> Void) {
        let total = target.lifetime
        guard total > 0, !target.legs.isEmpty else {
            completion()
            return
        }

        let surfaces = target.kind.movementStyle.surfaces
        var current = surfaces ? point(for: target.start) : offscreenPoint(for: target.start)
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
            // Artwork faces up, hence the +π/2.
            var legHeading = atan2(destination.y - current.y, destination.x - current.x) + .pi / 2
            if index > 0 {
                while legHeading - heading > .pi { legHeading -= 2 * .pi }
                while legHeading - heading < -.pi { legHeading += 2 * .pi }
            }
            heading = legHeading

            // After a pause, turn on the spot; otherwise curve into the new heading.
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
                } else if leg.underCover {
                    let peek = peekPoint(from: destination)
                    for (fraction, point) in [(0.3, peek), (0.45, destination), (0.65, peek), (0.8, destination)] {
                        positions.append(NSValue(cgPoint: point))
                        positionTimes.append(NSNumber(value: (elapsed + leg.pause * fraction) / total))
                    }
                }
                elapsed += leg.pause
                positions.append(NSValue(cgPoint: destination))
                positionTimes.append(NSNumber(value: elapsed / total))
            }
            previousPause = leg.pause
            current = destination
        }
        // Guard against floating-point drift on the final key time.
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

        let turns = target.kind.turnsToFaceMovement
        let group = CAAnimationGroup()
        group.animations = turns ? [move, turn] : [move]
        group.duration = total
        if surfaces {
            group.animations?.append(surfacingFade(total: total))
            // Hold the faded-out final frame until the view is recycled.
            group.fillMode = .forwards
            group.isRemovedOnCompletion = false
        }

        critter.transform = turns ? CGAffineTransform(rotationAngle: heading) : .identity
        critter.center = current
        critter.alpha = surfaces ? CGFloat(Self.underwaterOpacity) : 1

        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        critter.layer.add(group, forKey: "path")
        CATransaction.commit()

        if surfaces {
            addTailSwish(to: critter)
            emitRing(at: point(for: target.start), color: Self.waterRippleColor, endRadius: 70, lineWidth: 2)
        }
    }

    static let underwaterOpacity: Float = 0.78
    static let waterRippleColor = UIColor(red: 0.6, green: 0.85, blue: 1, alpha: 0.6)

    private func surfacingFade(total: TimeInterval) -> CAKeyframeAnimation {
        let fadeTime = min(0.8, total / 4)
        let fade = CAKeyframeAnimation(keyPath: "opacity")
        fade.values = [0, Self.underwaterOpacity, Self.underwaterOpacity, 0]
        fade.keyTimes = [0, NSNumber(value: fadeTime / total), NSNumber(value: 1 - fadeTime / total), 1]
        return fade
    }

    private func addTailSwish(to critter: UIView) {
        let swish = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        swish.isAdditive = true
        swish.values = [0, 0.14, 0, -0.14, 0]
        swish.duration = 0.7
        swish.repeatCount = .infinity
        critter.layer.add(swish, forKey: "swish")
    }

    func peekPoint(from point: CGPoint) -> CGPoint {
        let angle = CGFloat.random(in: 0..<(2 * .pi))
        let reach = hidingSpotSize / 2
        return CGPoint(x: point.x + cos(angle) * reach, y: point.y + sin(angle) * reach)
    }

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

    /// Like `point(for:)`, but border points are pushed fully off-screen.
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
