//
//  CritterActions.swift
//  pawpaw
//

import SpriteKit

/// Turns a target's normalized legs into actions for each part of a `CritterNode`.
enum CritterActions {
    /// A value reached at `time` seconds after the path started.
    typealias Keyframe<Value> = (time: TimeInterval, value: Value)

    /// Poses shown in turn for `frameTime` each, over and over, from `start` for `duration`.
    /// The critter goes back to its resting pose afterwards.
    struct PoseCue: Equatable {
        let start: TimeInterval
        let duration: TimeInterval
        let poses: [PlayfieldTextures.CritterPose]
        let frameTime: TimeInterval
    }

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
        /// In time order, without overlaps.
        let poses: [PoseCue]
        /// Rippled along its length by a `RibbonWave`.
        let ripples: Bool
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
        var positions: [Keyframe<CGPoint>] = []
        var headings: [Keyframe<CGFloat>] = []
        var jiggle = Timeline()
        var body = Timeline()
        var wings = Timeline()
        var poses: [PoseCue] = []
        var previousPause: TimeInterval = 0
        /// Indexes into `positions` of moves that speed up or slow down rather than keep pace.
        var easing: [Int: SKActionTimingMode] = [:]

        /// Steps, wingbeats and stride poses for one move, so feet keep going whenever it moves.
        func addMotion(
            from a: CGPoint, to b: CGPoint, at time: TimeInterval, over travel: TimeInterval,
            flies: Bool
        ) {
            // Waiting in place, such as off-screen before coming back, takes no steps.
            let distance = hypot(b.x - a.x, b.y - a.y)
            guard travel > 0, distance > 0.5 else { return }
            let slowdown = strideSlowdown(
                for: target.kind, speed: distance / travel, bodyLength: geometry.targetSize)
            if flies {
                if let beat = wingbeat(for: target.kind, travel: travel) {
                    wings.add(beat, at: time)
                }
            } else if let legStride = strideAction(
                for: target.kind, travel: travel, slowdown: slowdown)
            {
                if legStride.onBody {
                    body.add(legStride.action, at: time)
                } else {
                    jiggle.add(legStride.action, at: time)
                }
            }
            if let cycle = poseCycle(
                for: target.kind, travel: travel, flies: flies, slowdown: slowdown)
            {
                // A short move still fits one whole step.
                let frameTime = min(cycle.frameTime, travel / Double(cycle.poses.count))
                poses.append(
                    PoseCue(
                        start: time, duration: travel, poses: cycle.poses, frameTime: frameTime))
            }
        }

        func addMotion(
            through keys: [Keyframe<CGPoint>], from point: CGPoint, at time: TimeInterval
        ) {
            var previous = (time: time, value: point)
            for key in keys {
                addMotion(
                    from: previous.value, to: key.value, at: previous.time,
                    over: key.time - previous.time, flies: false)
                previous = key
            }
        }

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
            if index == 0 {
                headings.append((elapsed, heading))
            } else if style == .swim {
                // A fish flicks round as it sets off, then glides, rather than drifting
                // sideways down the leg.
                headings.append((elapsed + min(swimTurnTime, leg.travel / 2), heading))
            } else if leg.flies {
                // Turns as it takes off, so it never flies off sideways or tail first.
                headings.append((elapsed + min(takeOffTurnTime, leg.travel / 4), heading))
            } else if previousPause > 0 {
                // After a pause, turn on the spot; otherwise curve into the new heading.
                headings.append((elapsed, heading))
            }
            addMotion(
                from: current, to: destination, at: elapsed, over: leg.travel, flies: leg.flies)
            elapsed += leg.travel
            headings.append((elapsed, heading))
            // Coming on from off-screen, it slows to a stop rather than braking at full speed,
            // and a fish coasts in under a lily pad.
            if (index == 0 && !style.surfaces && MovementPlanner.isOnEdge(target.start))
                || (leg.underCover && style.surfaces)
            {
                easing[positions.count] = .easeOut
            }
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
                    let trip: [Keyframe<CGPoint>] = [
                        (elapsed + hide, edge), (elapsed + pause - hide, edge),
                    ]
                    addMotion(
                        through: trip + [(elapsed + pause, destination)], from: destination,
                        at: elapsed)
                    positions += trip
                    heading = out + .pi
                } else if leg.underCover, style.surfaces {
                    // Turns while hidden, noses out once, then backs under, facing out.
                    let peek =
                        leg.peek.map { geometry.point(for: $0) }
                        ?? geometry.peekPoint(from: destination)
                    let out = facing(from: destination, to: peek, near: heading)
                    headings += [(elapsed + pause * 0.3, out), (elapsed + pause, out)]
                    let peeks = freezeKeys(
                        [(0.3, destination), (0.6, peek), (0.7, peek), (0.95, destination)],
                        from: elapsed, over: pause)
                    easing[positions.count + 1] = .easeInEaseOut
                    easing[positions.count + 3] = .easeInEaseOut
                    positions += peeks
                    heading = out
                } else if leg.underCover {
                    let peek =
                        leg.peek.map { geometry.point(for: $0) }
                        ?? geometry.peekPoint(from: destination)
                    let peeks = freezeKeys(
                        [(0.3, peek), (0.45, destination), (0.65, peek), (0.8, destination)],
                        from: elapsed, over: pause)
                    addMotion(through: peeks, from: destination, at: elapsed)
                    positions += peeks
                } else if style.nodsDuringFreeze {
                    let nod = geometry.nodPoint(from: current, to: destination)
                    positions += freezeKeys(
                        [(0.2, nod), (0.35, destination), (0.55, nod), (0.7, destination)],
                        from: elapsed, over: pause)
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
        for key in headings {
            turn.key(at: key.time) {
                .rotate(toAngle: key.value, duration: $0, shortestUnitArc: false)
            }
        }
        let loops = styleLoops(for: target, total: total)
        if style.surfaces {
            // Each tail pose is centred on a peak of the sway, so the tail is swept furthest
            // as the body swings furthest, and straight as it swings back through the middle.
            // The sway turns the head left first, which throws the tail right: `_move2`.
            let frameTime = swimSwayPeriod / TimeInterval(swimFrames.count)
            poses = [
                PoseCue(
                    start: frameTime / 2, duration: total - frameTime / 2, poses: swimFrames,
                    frameTime: frameTime)
            ]
        }
        return Plan(
            start: start,
            heading: turns ? startHeading : 0,
            opacity: style.surfaces ? 0 : 1,
            path: path(
                through: positions, from: start, smooth: style.slithers, easing: easing),
            turn: turns ? turn.sequence : nil,
            jiggle: jiggle.actionIfAny + loops.jiggle,
            wings: wings.actionIfAny + loops.wings,
            body: body.actionIfAny + loops.body,
            poses: poses,
            ripples: target.kind.wavesAlongBody
        )
    }
}

extension CritterActions {
    fileprivate static let swimSwayPeriod: TimeInterval = 0.7
    /// How long a fish takes to turn onto a new leg without stopping.
    fileprivate static let swimTurnTime: TimeInterval = 0.35
    /// How long a flier takes to turn toward where it's flying, as it lifts off.
    fileprivate static let takeOffTurnTime: TimeInterval = 0.15
    /// One step, back through rest, then the opposite step.
    fileprivate static let strideFrames: [PlayfieldTextures.CritterPose] = [
        .moving, .rest, .movingAlternate, .rest,
    ]
    /// The tail swept right, back through straight, then swept left.
    fileprivate static let swimFrames: [PlayfieldTextures.CritterPose] = [
        .movingAlternate, .rest, .moving, .rest,
    ]

    /// The poses to cycle through during a move of `travel` seconds, for critters that have
    /// more than one. `slowdown` stretches each step, from `strideSlowdown`.
    fileprivate static func poseCycle(
        for kind: TargetKind, travel: TimeInterval, flies: Bool, slowdown: Double
    ) -> (poses: [PlayfieldTextures.CritterPose], frameTime: TimeInterval)? {
        if flies { return kind.flyingImageName == nil ? nil : ([.flying], travel) }
        switch kind {
        case .mouse: return (strideFrames, 0.04 * slowdown)
        case .lizard: return (strideFrames, 0.05 * slowdown)
        // Six legs are never all at rest: half reach forward as the other half push back.
        case .bug: return ([.moving, .movingAlternate], 0.08 * slowdown)
        // Legs kicked out for the whole hop.
        case .cricket: return ([.moving], travel)
        case .fish, .butterfly, .feather, .laser, .ribbon, .bird: return nil
        }
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
            jiggle.append(.repeatForever(sway(0.14, period: swimSwayPeriod)))
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

    /// A sine wave turning anticlockwise first. Unlike `swing`, it slows only at the sides, so
    /// it neither bounces off them nor hitches at the middle.
    fileprivate static func sway(_ amount: CGFloat, period: TimeInterval) -> SKAction {
        .customAction(withDuration: period) { node, elapsed in
            node.zRotation = amount * sin(2 * .pi * elapsed / CGFloat(period))
        }
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

    /// Points reached at `fractions` of a freeze that starts `elapsed` seconds into the path.
    fileprivate static func freezeKeys(
        _ fractions: [(fraction: Double, point: CGPoint)], from elapsed: TimeInterval,
        over pause: TimeInterval
    ) -> [Keyframe<CGPoint>] {
        fractions.map { (time: elapsed + pause * $0.fraction, value: $0.point) }
    }

    /// `easing` is the timing of the move to each key, by index, when it isn't linear.
    fileprivate static func path(
        through keys: [Keyframe<CGPoint>], from start: CGPoint, smooth: Bool,
        easing: [Int: SKActionTimingMode] = [:]
    ) -> SKAction {
        let points = [start] + keys.map(\.value)
        var timeline = Timeline()
        for (index, key) in keys.enumerated() {
            timeline.key(at: key.time) { duration in
                let move = segment(
                    to: key, index: index, points: points, smooth: smooth, duration: duration)
                if let mode = easing[index] { move.timingMode = mode }
                return move
            }
        }
        return timeline.sequence
    }

    private static func segment(
        to key: Keyframe<CGPoint>, index: Int, points: [CGPoint], smooth: Bool,
        duration: TimeInterval
    ) -> SKAction {
        guard smooth else { return .move(to: key.value, duration: duration) }
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

    /// How much longer each step takes than at a full run, from 1 to 3, so the feet keep pace
    /// with the ground rather than pattering on the spot. `speed` is in points per second.
    fileprivate static func strideSlowdown(
        for kind: TargetKind, speed: CGFloat, bodyLength: CGFloat
    ) -> Double {
        // Body lengths covered by one full stride, and the quickest that stride can be.
        let gait: (length: CGFloat, fastest: TimeInterval)
        switch kind {
        case .mouse: gait = (1.0, 0.16)
        case .lizard: gait = (1.0, 0.2)
        case .bug: gait = (0.35, 0.16)
        case .cricket, .bird, .fish, .butterfly, .feather, .laser, .ribbon: return 1
        }
        let cycle = Double(gait.length * bodyLength / speed)
        return min(max(cycle / gait.fastest, 1), 3)
    }

    /// Wings opening and closing in flight, shown by narrowing the whole critter.
    /// The ladybug's wings blur too fast to see, so it only rises and settles a little.
    fileprivate static func wingbeat(for kind: TargetKind, travel: TimeInterval) -> SKAction? {
        switch kind {
        case .bird:
            let beat = pulse([0, -0.3, 0], period: 0.18, eased: true, xOnly: true)
            return .repeat(beat, count: max(1, Int((travel / beat.duration).rounded())))
        case .bug: return pulse([0, 0.06, 0.04, 0.06, 0], period: travel, eased: true)
        default: return nil
        }
    }

    /// Legs that scuttle or hop, only while travelling so a frozen critter stays still.
    /// `slowdown` stretches each step, from `strideSlowdown`.
    fileprivate static func strideAction(
        for kind: TargetKind, travel: TimeInterval, slowdown: Double
    ) -> (action: SKAction, onBody: Bool)? {
        func repeated(_ cycle: SKAction) -> SKAction {
            .repeat(cycle, count: max(1, Int((travel / cycle.duration).rounded())))
        }
        // A short move still fits one whole step.
        func period(_ fastest: TimeInterval) -> TimeInterval {
            min(fastest * slowdown, max(travel, fastest))
        }
        switch kind {
        // Small sways: the stride poses already turn the head and swing the tail.
        case .mouse, .bug: return (repeated(swing(0.04, period: period(0.16), eased: false)), false)
        case .lizard: return (repeated(swing(0.07, period: period(0.2), eased: false)), false)
        // One springy stretch per hop.
        case .cricket: return (pulse([0, 0.16, 0], period: travel, eased: false), true)
        case .bird: return (repeated(pulse([0, 0.1, 0], period: 0.2, eased: false)), true)
        case .butterfly, .feather, .laser, .fish, .ribbon: return nil
        }
    }
}
