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

        let style = target.kind.movementStyle
        let surfaces = style.surfaces
        let turns = target.kind.turnsToFaceMovement
        var current = surfaces ? point(for: target.start) : offscreenPoint(for: target.start)
        var positions = [NSValue(cgPoint: current)]
        var positionTimes: [NSNumber] = [0]
        var rotations: [NSNumber] = []
        var rotationTimes: [NSNumber] = []
        var twitches: [Twitch] = []

        func addRotation(_ value: CGFloat, at time: TimeInterval) {
            rotations.append(NSNumber(value: Double(value)))
            rotationTimes.append(NSNumber(value: time / total))
        }

        // Hold off-screen at the start while the appear sound plays.
        var elapsed = target.leadIn
        if elapsed > 0 {
            positions.append(NSValue(cgPoint: current))
            positionTimes.append(NSNumber(value: elapsed / total))
        }
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

            if index == 0, elapsed > 0 {
                addRotation(heading, at: 0)
            }
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
                } else if style.pecks {
                    let nod = nodPoint(from: current, to: destination)
                    for (fraction, point) in [(0.2, nod), (0.35, destination), (0.55, nod), (0.7, destination)] {
                        positions.append(NSValue(cgPoint: point))
                        positionTimes.append(NSNumber(value: (elapsed + leg.pause * fraction) / total))
                    }
                } else {
                    twitches += self.twitches(from: elapsed, during: leg.pause, style: style, turns: turns)
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
        // A smoothed path turns the zigzag legs into S-curves.
        move.calculationMode = style.slithers ? .cubic : .linear

        let turn = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        turn.values = rotations
        turn.keyTimes = rotationTimes
        turn.calculationMode = .linear

        let group = CAAnimationGroup()
        var animations: [CAAnimation] = turns ? [move, turn] : [move]
        animations += twitchAnimations(for: twitches, style: style, total: total)
        group.animations = animations
        group.duration = total
        // Cats track motion closely and notice flicker above 60 Hz, so ask ProMotion screens for 120 Hz.
        group.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)
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
        if style.slithers {
            addSlither(to: critter)
        }
        if style.fliesOff, let flight = target.legs.last, flight.exits {
            addFlap(to: critter, after: total - flight.travel, lasting: flight.travel)
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

    /// A slower, wider sway than the tail swish, so the whole ribbon seems to weave.
    private func addSlither(to critter: UIView) {
        let sway = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        sway.isAdditive = true
        sway.values = [0, 0.3, 0, -0.3, 0]
        sway.duration = 1.0
        sway.repeatCount = .infinity
        critter.layer.add(sway, forKey: "slither")
    }

    /// Quick wingbeats, shown as a widening pulse, while it flies off.
    private func addFlap(to critter: UIView, after delay: TimeInterval, lasting duration: TimeInterval) {
        let beat: TimeInterval = 0.1
        let flap = CAKeyframeAnimation(keyPath: "transform.scale.x")
        flap.isAdditive = true
        flap.values = [0, 0.35, 0]
        flap.duration = beat
        flap.repeatCount = Float(duration / beat)
        flap.beginTime = critter.layer.convertTime(CACurrentMediaTime(), from: nil) + delay
        critter.layer.add(flap, forKey: "flap")
    }

    /// A short peck forward along the last move.
    private func nodPoint(from previous: CGPoint, to point: CGPoint) -> CGPoint {
        let dx = point.x - previous.x
        let dy = point.y - previous.y
        let length = max(hypot(dx, dy), 1)
        let reach: CGFloat = 10
        return CGPoint(x: point.x + dx / length * reach, y: point.y + dy / length * reach)
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
