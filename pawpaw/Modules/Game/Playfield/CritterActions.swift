//
//  CritterActions.swift
//  pawpaw
//

import SpriteKit

/// Turns a target's normalized legs into actions for each part of a `CritterNode`.
enum CritterActions {
    struct Plan {
        let start: CGPoint
        /// SpriteKit radians (anticlockwise), with the artwork facing up at 0.
        let heading: CGFloat
        let opacity: CGFloat
        /// The critter escapes when it ends.
        let path: SKAction
        let turn: SKAction?
        let jiggle: [SKAction]
        let wings: [SKAction]
        let body: [SKAction]
    }

    static func plan(for target: GameTarget, in geometry: PlayfieldGeometry) -> Plan? {
        let total = target.lifetime
        guard total > 0, !target.legs.isEmpty else { return nil }
        let style = target.kind.movementStyle
        let turns = target.kind.turnsToFaceMovement
        let start =
            style.surfaces
            ? geometry.point(for: target.start) : geometry.offscreenPoint(for: target.start)
        var current = start
        var heading: CGFloat = 0
        var startHeading: CGFloat = 0
        var positions: [(TimeInterval, CGPoint)] = []
        var headings: [(TimeInterval, CGFloat)] = []
        var jiggle = Timeline()
        var body = Timeline()
        var previousPause: TimeInterval = 0

        // Hold off-screen at the start while the appear sound plays.
        var elapsed = target.leadIn
        if elapsed > 0 {
            positions.append((elapsed, start))
        }
        for (index, leg) in target.legs.enumerated() {
            let destination =
                leg.exits
                ? geometry.offscreenPoint(for: leg.destination)
                : geometry.point(for: leg.destination)
            heading = facing(from: current, to: destination, near: index == 0 ? nil : heading)
            if index == 0 { startHeading = heading }
            // After a pause, turn on the spot; otherwise curve into the new heading.
            if index == 0 || previousPause > 0 {
                headings.append((elapsed, heading))
            }
            if let legStride = strideAction(for: target.kind, travel: leg.travel) {
                if legStride.onBody {
                    body.add(legStride.action, at: elapsed)
                } else {
                    jiggle.add(legStride.action, at: elapsed)
                }
            }
            elapsed += leg.travel
            headings.append((elapsed, heading))
            positions.append((elapsed, destination))

            let pause = leg.pause
            if pause > 0 {
                if leg.hides {
                    let edge = geometry.hideEdgePoint(from: destination)
                    let out = facing(from: destination, to: edge, near: heading)
                    let hide = MovementPlanner.hideTravel
                    headings += [
                        (elapsed + 0.1, out), (elapsed + hide, out),
                        (elapsed + pause - hide, out + .pi),
                        (elapsed + pause - 0.12, out + .pi),
                    ]
                    positions += [(elapsed + hide, edge), (elapsed + pause - hide, edge)]
                    heading = out + .pi
                } else if leg.underCover {
                    let peek =
                        leg.peek.map { geometry.point(for: $0) }
                        ?? geometry.peekPoint(from: destination)
                    positions += [
                        (0.3, peek), (0.45, destination), (0.65, peek), (0.8, destination),
                    ].map {
                        (elapsed + pause * $0.0, $0.1)
                    }
                } else if style.pecks {
                    let nod = geometry.nodPoint(from: current, to: destination)
                    positions += [(0.2, nod), (0.35, destination), (0.55, nod), (0.7, destination)]
                        .map {
                            (elapsed + pause * $0.0, $0.1)
                        }
                } else if style.doesPushUps {
                    // The body seems to rise toward the camera.
                    body.add(
                        pulse([0, 0.08, 0, 0.08, 0], period: pause * 0.4, eased: false),
                        at: elapsed + pause * 0.3)
                } else {
                    for twitch in twitches(during: pause, style: style, turns: turns) {
                        jiggle.add(twitch.action, at: elapsed + twitch.start)
                    }
                }
                elapsed += pause
                positions.append((elapsed, destination))
            }
            previousPause = pause
            current = destination
        }

        var turn = Timeline()
        headings.forEach { key in
            turn.key(at: key.0) { .rotate(toAngle: key.1, duration: $0, shortestUnitArc: false) }
        }
        let loops = styleLoops(for: target, total: total)
        return Plan(
            start: start,
            heading: turns ? startHeading : 0,
            opacity: style.surfaces ? 0 : 1,
            path: path(through: positions, from: start, smooth: style.slithers),
            turn: turns ? turn.sequence : nil,
            jiggle: [jiggle.sequence] + loops.jiggle,
            wings: loops.wings,
            body: [body.sequence] + loops.body
        )
    }
}

extension CritterActions {
    fileprivate static func styleLoops(for target: GameTarget, total: TimeInterval) -> (
        jiggle: [SKAction], wings: [SKAction], body: [SKAction]
    ) {
        let style = target.kind.movementStyle
        var jiggle: [SKAction] = []
        var wings: [SKAction] = []
        var body: [SKAction] = []
        if style.surfaces {
            let fade = min(0.8, total / 4)
            let opacity: CGFloat = 0.78
            body.append(
                .sequence([
                    .fadeAlpha(to: opacity, duration: fade), .wait(forDuration: total - fade * 2),
                    .fadeAlpha(to: 0, duration: fade),
                ]))
            jiggle.append(.repeatForever(swing(0.14, period: 0.7, eased: false)))
        }
        if style.slithers {
            // A slower, wider sway than the tail swish, so the whole ribbon seems to weave.
            jiggle.append(.repeatForever(swing(0.3, period: 1.0, eased: false)))
        }
        if style.fliesOff, let flight = target.legs.last, flight.exits {
            // Quick wingbeats, shown as the wings folding in and opening out.
            let flap = SKAction.repeat(
                pulse([0, -0.45, 0], period: 0.1, eased: false, xOnly: true),
                count: max(1, Int(flight.travel / 0.1)))
            wings.append(.sequence([.wait(forDuration: total - flight.travel), flap]))
        }
        switch target.kind {
        case .butterfly:
            wings.append(
                .repeatForever(pulse([0, -0.55, 0], period: 0.18, eased: true, xOnly: true)))
        case .feather: jiggle.append(.repeatForever(swing(0.25, period: 1.6, eased: true)))
        case .laser: body.append(.repeatForever(pulse([0, 0.12, 0], period: 0.5, eased: true)))
        default: break
        }
        return (jiggle, wings, body)
    }

    /// Artwork faces up, hence the -π/2. Unwrapped near `reference` so turns take the short way.
    fileprivate static func facing(from start: CGPoint, to end: CGPoint, near reference: CGFloat?)
        -> CGFloat
    {
        var angle = atan2(end.y - start.y, end.x - start.x) - .pi / 2
        guard let reference else { return angle }
        while angle - reference > .pi { angle -= 2 * .pi }
        while angle - reference < -.pi { angle += 2 * .pi }
        return angle
    }

    fileprivate static func path(
        through keys: [(TimeInterval, CGPoint)], from start: CGPoint, smooth: Bool
    ) -> SKAction {
        let points = [start] + keys.map(\.1)
        var timeline = Timeline()
        for (index, key) in keys.enumerated() {
            timeline.key(at: key.0) { duration in
                guard smooth else { return .move(to: key.1, duration: duration) }
                // Catmull-Rom through the neighbours turns the zigzag legs into S-curves.
                let a = points[max(index - 1, 0)]
                let b = points[index]
                let c = points[index + 1]
                let d = points[min(index + 2, points.count - 1)]
                let curve = CGMutablePath()
                curve.move(to: b)
                curve.addCurve(
                    to: c,
                    control1: CGPoint(x: b.x + (c.x - a.x) / 6, y: b.y + (c.y - a.y) / 6),
                    control2: CGPoint(x: c.x - (d.x - b.x) / 6, y: c.y - (d.y - b.y) / 6)
                )
                return .follow(curve, asOffset: false, orientToPath: false, duration: duration)
            }
        }
        return timeline.sequence
    }

    /// Legs that scuttle or hop, only while travelling so a frozen critter stays still.
    fileprivate static func strideAction(for kind: TargetKind, travel: TimeInterval) -> (
        action: SKAction, onBody: Bool
    )? {
        func repeated(_ cycle: SKAction) -> SKAction {
            .repeat(cycle, count: max(1, Int(travel / cycle.duration)))
        }
        switch kind {
        case .mouse: return (repeated(swing(0.07, period: 0.16, eased: false)), false)
        case .bug: return (repeated(swing(0.1, period: 0.1, eased: false)), false)
        case .lizard: return (repeated(swing(0.14, period: 0.2, eased: false)), false)
        // One springy stretch per hop.
        case .cricket: return (pulse([0, 0.16, 0], period: travel, eased: false), true)
        case .bird: return (repeated(pulse([0, 0.1, 0], period: 0.2, eased: false)), true)
        case .butterfly, .feather, .laser, .fish, .ribbon: return nil
        }
    }
}
