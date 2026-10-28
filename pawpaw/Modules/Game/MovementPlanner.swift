//
//  MovementPlanner.swift
//  pawpaw
//

import CoreGraphics
import Foundation

/// Builds stop-and-go paths inside the normalized (0...1) play field.
enum MovementPlanner {
    /// Time a hiding critter takes to run off the edge, and the same again to come back.
    static let hideTravel: TimeInterval = 0.4
    /// Shortest freeze that is long enough to run off the edge, wait unseen and run back.
    static let minimumHidePause: TimeInterval = 1.0
    /// Time spent running off the edge at the end of a journey.
    static let exitTravel: TimeInterval = 0.9
    /// Shortest wait under a hiding spot: long enough to peek out twice.
    static let minimumCoverPause: TimeInterval = 1.6

    /// Normalized centers for `count` hiding spots, away from the edges and from each other.
    static func hidingSpots(count: Int) -> [CGPoint] {
        var spots: [CGPoint] = []
        var attempts = 0
        while spots.count < count, attempts < 50 {
            attempts += 1
            let candidate = CGPoint(x: CGFloat.random(in: 0.2...0.8), y: CGFloat.random(in: 0.25...0.75))
            let isClear = spots.allSatisfy { hypot($0.x - candidate.x, $0.y - candidate.y) >= 0.35 }
            if isClear || attempts == 50 { spots.append(candidate) }
        }
        return spots
    }

    /// `coverSpots` are hiding spots a critter may run under during a long freeze.
    static func legs(
        from start: CGPoint,
        style: MovementStyle,
        duration: TimeInterval,
        coverSpots: [CGPoint] = []
    ) -> [PathLeg] {
        let count = Int.random(in: style.legCount)
        let pauseTotal = count > 1 ? duration * style.pauseFraction : 0
        let pauses = split(pauseTotal, into: count - 1)
        let travels = split(duration - pauseTotal, into: count)

        var legs: [PathLeg] = []
        var current = start
        var heading = Double.random(in: 0..<(2 * .pi))
        var hasTakenCover = false
        for index in 0..<count {
            let hasPause = index < pauses.count
            var pause = hasPause ? pauses[index] : 0
            let longFreeze = pause >= minimumHidePause
            // Land critters only take cover during a long freeze; a fish can glide under a lily pad on any hover.
            let mayTakeCover = hasPause && !hasTakenCover && (longFreeze || style.surfaces)
            let destination: CGPoint
            let underCover: Bool
            if mayTakeCover, let spot = coverSpots.randomElement(), Double.random(in: 0..<1) < style.coverChance {
                // Run for cover, like a mouse ducking under a box or a koi under a lily pad.
                destination = spot
                underCover = true
                hasTakenCover = true
                // Stay long enough to peek out twice. This makes the journey a little longer.
                pause = max(pause, minimumCoverPause)
                heading = atan2(Double(spot.y - current.y), Double(spot.x - current.x))
            } else {
                heading += Double.random(in: style.turnRange) * (Bool.random() ? 1 : -1)
                destination = nextPoint(
                    from: current,
                    heading: &heading,
                    distance: Double.random(in: style.distanceRange)
                )
                underCover = false
            }
            legs.append(PathLeg(
                destination: destination,
                travel: travels[index],
                pause: pause,
                hides: !underCover && longFreeze && Double.random(in: 0..<1) < style.hideChance,
                underCover: underCover
            ))
            current = destination
        }
        // Fish sink back into the depths where they are; the view fades them out.
        if style.surfaces { return legs }
        // Critters leave the way real prey does: they run off the edge instead of vanishing.
        legs.append(PathLeg(
            destination: nearestEdgePoint(to: current),
            travel: exitTravel,
            pause: 0,
            hides: false,
            exits: true
        ))
        return legs
    }

    /// The point on the field's border closest to `point`.
    private static func nearestEdgePoint(to point: CGPoint) -> CGPoint {
        let gaps = [point.x, 1 - point.x, point.y, 1 - point.y]
        switch gaps.firstIndex(of: gaps.min() ?? 0) {
        case 0: return CGPoint(x: 0, y: point.y)
        case 1: return CGPoint(x: 1, y: point.y)
        case 2: return CGPoint(x: point.x, y: 0)
        default: return CGPoint(x: point.x, y: 1)
        }
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
