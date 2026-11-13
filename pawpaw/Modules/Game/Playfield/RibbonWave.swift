//
//  RibbonWave.swift
//  pawpaw
//

import SpriteKit

/// Ripples a straight ribbon sprite like a wand toy's ribbon. A wave runs from the knot at the
/// top down to the tail, quicker and wider the faster the ribbon moves, and the tail swings
/// wide on turns. Speed and turning come from the critter's own position and heading.
/// Nonisolated: the runtime's main-actor deinit crashes when the last reference goes in a test.
nonisolated final class RibbonWave {
    /// Rows of the warp grid, from the tail (0) to the knot.
    static let rows = 12
    /// Sideways swing at the tail, in texture widths. The texture is padded for the shadow,
    /// so the ribbon itself is a narrow strip down the middle.
    static let restingAmplitude: Float = 0.06
    static let runningAmplitude: Float = 0.16
    /// How many waves fit along the ribbon at once.
    static let wavesAlongLength: Float = 1.5
    /// Waves a second.
    static let restingFrequency: Double = 0.7
    static let runningFrequency: Double = 2
    /// Body lengths a second that count as a full run.
    static let runningSpeed: CGFloat = 2.5
    /// Tail swing, in texture widths, per radian a second of turning, and the most it swings.
    static let turnSwing: Float = 0.05
    static let maxTurnSwing: Float = 0.16
    /// How fast changes in speed and turning show, per second.
    static let responsiveness: Double = 6

    private let bodyLength: CGFloat
    private var phase: Double = 0
    /// 0 at rest, 1 at a full run.
    private var effort: Double = 0
    /// Radians a second, anticlockwise.
    private var turnRate: Double = 0
    private var lastTime: TimeInterval?
    private var lastPosition: CGPoint?
    private var lastHeading: CGFloat?

    init(bodyLength: CGFloat) {
        self.bodyLength = bodyLength
    }

    /// For a new action whose clock starts at zero. Keeps the wave where it was.
    func restartClock() {
        lastTime = nil
    }

    func warp(at time: TimeInterval, position: CGPoint, heading: CGFloat) -> SKWarpGeometryGrid {
        let offsets = offsets(at: time, position: position, heading: heading)
        var source: [SIMD2<Float>] = []
        var destination: [SIMD2<Float>] = []
        for (row, offset) in offsets.enumerated() {
            let y = Float(row) / Float(Self.rows)
            for x: Float in [0, 1] {
                source.append(SIMD2(x, y))
                destination.append(SIMD2(x + offset, y))
            }
        }
        return SKWarpGeometryGrid(
            columns: 1, rows: Self.rows, sourcePositions: source,
            destinationPositions: destination)
    }

    /// Sideways shift of each row, tail first, in texture widths.
    func offsets(at time: TimeInterval, position: CGPoint, heading: CGFloat) -> [Float] {
        advance(to: time, position: position, heading: heading)
        let amplitude =
            Self.restingAmplitude + (Self.runningAmplitude - Self.restingAmplitude) * Float(effort)
        let swing = min(
            max(-Float(turnRate) * Self.turnSwing, -Self.maxTurnSwing), Self.maxTurnSwing)
        return (0...Self.rows).map { row in
            // 0 at the knot, which the wand holds still, to 1 at the tail.
            let fromKnot = 1 - Float(row) / Float(Self.rows)
            let wave = sin(2 * .pi * Self.wavesAlongLength * fromKnot - Float(phase))
            return amplitude * fromKnot * wave + swing * fromKnot * fromKnot
        }
    }

    private func advance(to time: TimeInterval, position: CGPoint, heading: CGFloat) {
        let dt = lastTime.map { max(time - $0, 0) } ?? 0
        lastTime = time
        defer {
            lastPosition = position
            lastHeading = heading
        }
        guard dt > 0, let lastPosition, let lastHeading else { return }
        let speed = hypot(position.x - lastPosition.x, position.y - lastPosition.y) / dt
        let targetEffort = Double(min(speed / (Self.runningSpeed * bodyLength), 1))
        let targetTurn = Double(heading - lastHeading) / dt
        let blend = min(dt * Self.responsiveness, 1)
        effort += (targetEffort - effort) * blend
        turnRate += (targetTurn - turnRate) * blend
        let frequency =
            Self.restingFrequency + (Self.runningFrequency - Self.restingFrequency) * effort
        // Accumulated, so a change of speed never makes the wave jump.
        phase = (phase + 2 * .pi * frequency * dt).truncatingRemainder(dividingBy: 2 * .pi)
    }
}
