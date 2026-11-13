//
//  RibbonWaveTests.swift
//  pawpawTests
//

import CoreGraphics
import XCTest

@testable import pawpaw

@MainActor
final class RibbonWaveTests: XCTestCase {
    private let bodyLength: CGFloat = 100

    /// Steps `wave` for `seconds` at 60 fps, moving `speed` points a second and turning
    /// `turnRate` radians a second, and returns the last offsets.
    private func run(
        _ wave: RibbonWave, seconds: Double, speed: CGFloat = 0, turnRate: CGFloat = 0
    ) -> [Float] {
        var offsets: [Float] = []
        for frame in 0...Int(seconds * 60) {
            let time = Double(frame) / 60
            offsets = wave.offsets(
                at: time, position: CGPoint(x: speed * time, y: 0), heading: turnRate * time)
        }
        return offsets
    }

    private func largestSwing(_ wave: RibbonWave, speed: CGFloat) -> Float {
        _ = run(wave, seconds: 2, speed: speed)
        var largest: Float = 0
        for frame in 0..<60 {
            let time = 2 + Double(frame) / 60
            let tail =
                wave.offsets(
                    at: time, position: CGPoint(x: speed * time, y: 0), heading: 0
                ).first ?? 0
            largest = max(largest, abs(tail))
        }
        return largest
    }

    func testKnotStaysStillWhileTheTailMoves() {
        let offsets = run(RibbonWave(bodyLength: bodyLength), seconds: 1.3, speed: 200)
        XCTAssertEqual(offsets.count, RibbonWave.rows + 1)
        XCTAssertEqual(offsets.last ?? 1, 0, accuracy: 1e-6)
    }

    func testRipplesWiderWhenRunning() {
        let resting = largestSwing(RibbonWave(bodyLength: bodyLength), speed: 0)
        let running = largestSwing(RibbonWave(bodyLength: bodyLength), speed: 300)
        XCTAssertEqual(resting, RibbonWave.restingAmplitude, accuracy: 0.01)
        XCTAssertEqual(running, RibbonWave.runningAmplitude, accuracy: 0.01)
    }

    func testTailSwingsOutsideTheTurn() {
        let left = run(RibbonWave(bodyLength: bodyLength), seconds: 1, turnRate: 10)
        let right = run(RibbonWave(bodyLength: bodyLength), seconds: 1, turnRate: -10)
        // Seen from the ribbon, the path it came along curves away to the left.
        XCTAssertLessThan(left.first ?? 0, 0)
        XCTAssertGreaterThan(right.first ?? 0, 0)
    }

    func testRestartingTheClockKeepsTheWaveInPlace() {
        let wave = RibbonWave(bodyLength: bodyLength)
        let before = run(wave, seconds: 1, speed: 200)
        wave.restartClock()
        let after = wave.offsets(at: 0, position: CGPoint(x: 200, y: 0), heading: 0)
        for (a, b) in zip(before, after) {
            XCTAssertEqual(a, b, accuracy: 1e-6)
        }
    }
}
