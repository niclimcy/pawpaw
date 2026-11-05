//
//  MovementPlanner.swift
//  pawpaw
//

import CoreGraphics
import Foundation

/// Builds paths in the normalized (0...1) play field.
enum MovementPlanner {
    /// Each way, off the edge and back.
    static let hideTravel: TimeInterval = 0.4
    static let minimumHidePause: TimeInterval = 1.0
    static let exitTravel: TimeInterval = 0.9
    /// Fliers cross most of the field in this time.
    static let flightTravel: TimeInterval = 0.6
    static let earlyFlightChance = 0.4
    /// Long enough to peek out twice.
    static let minimumCoverPause: TimeInterval = 1.6
    /// Edge critters wait off-screen this long while their sound plays, then run in.
    static let leadInRange: ClosedRange<TimeInterval> = 0.5...0.8

    static func leadIn(for style: MovementStyle) -> TimeInterval {
        style.surfaces ? 0 : TimeInterval.random(in: leadInRange)
    }

    static func hidingSpots(count: Int) -> [CGPoint] {
        var spots: [CGPoint] = []
        var attempts = 0
        while spots.count < count, attempts < 50 {
            attempts += 1
            let candidate = CGPoint(
                x: CGFloat.random(in: 0.2...0.8), y: CGFloat.random(in: 0.25...0.75))
            let isClear = spots.allSatisfy { hypot($0.x - candidate.x, $0.y - candidate.y) >= 0.35 }
            if isClear || attempts == 50 { spots.append(candidate) }
        }
        return spots
    }

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
        let firstTurn: Double = Bool.random() ? 1 : -1
        // Fliers sometimes take off early, which shortens the path.
        let lastIndex =
            style.fliesOff && Double.random(in: 0..<1) < earlyFlightChance
            ? Int.random(in: 2..<max(count, 3))
            : count - 1
        for index in 0...lastIndex {
            let hasPause = index < pauses.count
            var pause = hasPause ? pauses[index] : 0
            let longFreeze = pause >= minimumHidePause
            // Land critters only take cover during a long freeze; a fish can glide under a lily pad on any hover.
            let mayTakeCover = hasPause && !hasTakenCover && (longFreeze || style.surfaces)
            let destination: CGPoint
            let underCover: Bool
            if mayTakeCover, let spot = coverSpots.randomElement(),
                Double.random(in: 0..<1) < style.coverChance
            {
                destination = spot
                underCover = true
                hasTakenCover = true
                // May lengthen the journey slightly.
                pause = max(pause, minimumCoverPause)
                heading = atan2(Double(spot.y - current.y), Double(spot.x - current.x))
            } else {
                let turn: Double =
                    style.slithers
                    ? firstTurn * (index.isMultiple(of: 2) ? 1 : -1)
                    : (Bool.random() ? 1 : -1)
                heading += Double.random(in: style.turnRange) * turn
                destination = nextPoint(
                    from: current,
                    heading: &heading,
                    distance: Double.random(in: style.distanceRange)
                )
                underCover = false
            }
            legs.append(
                PathLeg(
                    destination: destination,
                    travel: travels[index],
                    pause: pause,
                    hides: !underCover && longFreeze && Double.random(in: 0..<1) < style.hideChance,
                    underCover: underCover
                ))
            current = destination
        }
        // Surfacing critters fade out in place, fliers fly off and everything else exits via the nearest edge.
        if style.surfaces { return legs }
        legs.append(
            PathLeg(
                destination: style.fliesOff
                    ? flightEdgePoint(from: current) : nearestEdgePoint(to: current),
                travel: style.fliesOff ? flightTravel : exitTravel,
                pause: 0,
                hides: false,
                exits: true
            ))
        return legs
    }

    // MARK: Lure

    static let lureLegCount: ClosedRange<Int> = 3...5
    /// Long freezes give the cat time to stalk and line up a pounce.
    static let lurePauseFraction = 0.35
    static let finalLurePauseFraction = 0.5
    static let lureCoverChance = 0.6
    /// Normalized gap kept around the card when choosing open stops.
    private static let lureCoverMargin: CGFloat = 0.04
    private static let lureField = CGRect(x: 0.05, y: 0.05, width: 0.9, height: 0.9)

    /// One loop of the critter that roams the results. It never leaves; the last leg ends in a freeze
    /// and the next loop starts there. At most one stop is under the card, never the first or last,
    /// so each loop starts and ends in view. The final, easy catch never takes cover.
    static func lureLegs(
        from start: CGPoint,
        style: MovementStyle,
        legDuration: TimeInterval,
        cover: LureCover?,
        isFinal: Bool
    ) -> [PathLeg] {
        let count = Int.random(in: lureLegCount)
        let duration = legDuration * Double(count)
        let pauseTotal =
            duration
            * max(style.pauseFraction, isFinal ? finalLurePauseFraction : lurePauseFraction)
        let pauses = split(pauseTotal, into: count)
        let travels = split(duration - pauseTotal, into: count)
        let spots = isFinal ? [] : (cover?.spots ?? [])
        let coverIndex =
            count >= 3 && !spots.isEmpty && Double.random(in: 0..<1) < lureCoverChance
            ? Int.random(in: 1..<(count - 1))
            : nil

        var legs: [PathLeg] = []
        var current = start
        for index in 0..<count {
            if index == coverIndex, let spot = spots.randomElement() {
                legs.append(
                    PathLeg(
                        destination: spot.hide,
                        travel: travels[index],
                        pause: max(pauses[index], minimumCoverPause),
                        hides: false,
                        underCover: true,
                        peek: spot.peek
                    ))
                current = spot.hide
            } else {
                current = lureOpenPoint(from: current, style: style, avoiding: cover?.frame)
                legs.append(
                    PathLeg(
                        destination: current, travel: travels[index], pause: pauses[index],
                        hides: false))
            }
        }
        return legs
    }

    /// Off-screen on the side away from `touch` (the last paw, so roughly where the cat is),
    /// at a height or width that isn't behind the card when possible.
    static func lureEntryPoint(awayFrom touch: CGPoint?, avoiding cover: CGRect?) -> CGPoint {
        let blocked = cover?.insetBy(dx: -lureCoverMargin, dy: -lureCoverMargin)
        let entersFromSide: Bool
        let side: CGFloat
        if let touch {
            entersFromSide = abs(touch.x - 0.5) >= abs(touch.y - 0.5)
            side = (entersFromSide ? touch.x : touch.y) > 0.5 ? 0 : 1
        } else {
            entersFromSide = Bool.random()
            side = Bool.random() ? 0 : 1
        }
        func point(along: CGFloat, inset: CGFloat) -> CGPoint {
            let edge = side == 0 ? inset : 1 - inset
            return entersFromSide ? CGPoint(x: edge, y: along) : CGPoint(x: along, y: edge)
        }
        for _ in 0..<20 {
            let along = CGFloat.random(in: 0.1...0.9)
            if !(blocked?.contains(point(along: along, inset: 0.05)) ?? false) {
                return point(along: along, inset: 0)
            }
        }
        return point(along: CGFloat.random(in: 0.1...0.9), inset: 0)
    }

    /// A point clear of the card, a natural step away for `style` when there's room.
    static func lureOpenPoint(from point: CGPoint, style: MovementStyle, avoiding cover: CGRect?)
        -> CGPoint
    {
        let blocked = cover?.insetBy(dx: -lureCoverMargin, dy: -lureCoverMargin)
        func isOpen(_ candidate: CGPoint) -> Bool {
            lureField.contains(candidate) && !(blocked?.contains(candidate) ?? false)
        }
        for _ in 0..<20 {
            let heading = Double.random(in: 0..<(2 * .pi))
            let distance = max(Double.random(in: style.distanceRange), 0.15)
            let candidate = CGPoint(
                x: point.x + CGFloat(cos(heading) * distance),
                y: point.y + CGFloat(sin(heading) * distance)
            )
            if isOpen(candidate) { return candidate }
        }
        // No room nearby: anywhere open, which may mean running under the card.
        for _ in 0..<30 {
            let candidate = CGPoint(
                x: CGFloat.random(in: lureField.minX...lureField.maxX),
                y: CGFloat.random(in: lureField.minY...lureField.maxY)
            )
            if isOpen(candidate) { return candidate }
        }
        return CGPoint(
            x: min(max(point.x, lureField.minX), lureField.maxX),
            y: min(max(point.y, lureField.minY), lureField.maxY))
    }

    /// The lure wandering off when nobody has caught it for a while; surfacing critters fade out in place.
    static func lureExitLegs(from point: CGPoint, style: MovementStyle) -> [PathLeg] {
        if style.surfaces {
            return [PathLeg(destination: point, travel: 1.2, pause: 0, hides: false)]
        }
        return [
            PathLeg(
                destination: style.fliesOff
                    ? flightEdgePoint(from: point) : nearestEdgePoint(to: point),
                travel: style.fliesOff ? flightTravel : exitTravel * 1.5,
                pause: 0,
                hides: false,
                exits: true
            )
        ]
    }

    private static func nearestEdgePoint(to point: CGPoint) -> CGPoint {
        let gaps = [point.x, 1 - point.x, point.y, 1 - point.y]
        switch gaps.firstIndex(of: gaps.min() ?? 0) {
        case 0: return CGPoint(x: 0, y: point.y)
        case 1: return CGPoint(x: 1, y: point.y)
        case 2: return CGPoint(x: point.x, y: 0)
        default: return CGPoint(x: point.x, y: 1)
        }
    }

    /// Where a straight flight, roughly across the middle, leaves the field.
    private static func flightEdgePoint(from point: CGPoint) -> CGPoint {
        let heading =
            atan2(0.5 - Double(point.y), 0.5 - Double(point.x)) + Double.random(in: -0.8...0.8)
        let dx = cos(heading)
        let dy = sin(heading)
        let toSide =
            dx > 0 ? (1 - Double(point.x)) / dx : (dx < 0 ? -Double(point.x) / dx : .infinity)
        let toEnd =
            dy > 0 ? (1 - Double(point.y)) / dy : (dy < 0 ? -Double(point.y) / dy : .infinity)
        let reach = min(toSide, toEnd)
        var result = CGPoint(
            x: min(max(point.x + CGFloat(dx * reach), 0), 1),
            y: min(max(point.y + CGFloat(dy * reach), 0), 1)
        )
        // Snap onto the edge so the view pushes it fully off-screen.
        if toSide <= toEnd {
            result.x = dx > 0 ? 1 : 0
        } else {
            result.y = dy > 0 ? 1 : 0
        }
        return result
    }

    /// Slightly uneven pieces that sum to `total`.
    private static func split(_ total: TimeInterval, into parts: Int) -> [TimeInterval] {
        guard parts > 0 else { return [] }
        let weights = (0..<parts).map { _ in Double.random(in: 0.6...1.4) }
        let sum = weights.reduce(0, +)
        return weights.map { total * $0 / sum }
    }

    /// Turns away from the walls when a step would leave the field.
    private static func nextPoint(from point: CGPoint, heading: inout Double, distance: Double)
        -> CGPoint
    {
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
        // Boxed in: head for the center.
        heading = atan2(0.5 - Double(point.y), 0.5 - Double(point.x))
        return CGPoint(
            x: min(max(point.x + CGFloat(cos(heading) * distance), 0), 1),
            y: min(max(point.y + CGFloat(sin(heading) * distance), 0), 1)
        )
    }
}
