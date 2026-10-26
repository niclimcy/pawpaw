//
//  MovementPlanner.swift
//  pawpaw
//

import CoreGraphics
import Foundation

/// Builds stop-and-go paths inside the normalized (0...1) play field.
enum MovementPlanner {
    /// Shortest freeze that is long enough to fade out, wait unseen and fade back in.
    static let minimumHidePause: TimeInterval = 0.6

    static func legs(from start: CGPoint, style: MovementStyle, duration: TimeInterval) -> [PathLeg] {
        let count = Int.random(in: style.legCount)
        let pauseTotal = count > 1 ? duration * style.pauseFraction : 0
        let pauses = split(pauseTotal, into: count - 1)
        let travels = split(duration - pauseTotal, into: count)

        var legs: [PathLeg] = []
        var current = start
        var heading = Double.random(in: 0..<(2 * .pi))
        for index in 0..<count {
            let turn = Double.random(in: style.turnRange) * (Bool.random() ? 1 : -1)
            heading += turn
            let destination = nextPoint(
                from: current,
                heading: &heading,
                distance: Double.random(in: style.distanceRange)
            )
            let pause = index < pauses.count ? pauses[index] : 0
            legs.append(PathLeg(
                destination: destination,
                travel: travels[index],
                pause: pause,
                hides: pause >= minimumHidePause && Double.random(in: 0..<1) < style.hideChance
            ))
            current = destination
        }
        return legs
    }

    /// Splits `total` into `parts` slightly uneven pieces that add up to `total`.
    private static func split(_ total: TimeInterval, into parts: Int) -> [TimeInterval] {
        guard parts > 0 else { return [] }
        let weights = (0..<parts).map { _ in Double.random(in: 0.6...1.4) }
        let sum = weights.reduce(0, +)
        return weights.map { total * $0 / sum }
    }

    /// Steps along `heading`, turning away from the walls when the step would leave the field.
    private static func nextPoint(from point: CGPoint, heading: inout Double, distance: Double) -> CGPoint {
        for _ in 0..<12 {
            let candidate = CGPoint(
                x: point.x + CGFloat(cos(heading) * distance),
                y: point.y + CGFloat(sin(heading) * distance)
            )
            if (0...1).contains(candidate.x), (0...1).contains(candidate.y) {
                return candidate
            }
            heading += Double.random(in: (.pi / 2)...(.pi)) * (Bool.random() ? 1 : -1)
        }
        // Boxed in: head for the middle of the field.
        heading = atan2(0.5 - Double(point.y), 0.5 - Double(point.x))
        return CGPoint(
            x: min(max(point.x + CGFloat(cos(heading) * distance), 0), 1),
            y: min(max(point.y + CGFloat(sin(heading) * distance), 0), 1)
        )
    }
}
