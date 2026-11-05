//
//  LurePlannerTests.swift
//  pawpawTests
//

import CoreGraphics
import XCTest

@testable import pawpaw

@MainActor
final class LurePlannerTests: XCTestCase {
    private let cover = LureCover(
        frame: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4),
        spots: [
            LureCover.Spot(hide: CGPoint(x: 0.4, y: 0.35), peek: CGPoint(x: 0.4, y: 0.28)),
            LureCover.Spot(hide: CGPoint(x: 0.6, y: 0.65), peek: CGPoint(x: 0.6, y: 0.72)),
        ])

    private func loop(_ style: MovementStyle, isFinal: Bool = false) -> [PathLeg] {
        MovementPlanner.lureLegs(
            from: CGPoint(x: 0.1, y: 0.1), style: style, legDuration: 1.4, cover: cover,
            isFinal: isFinal)
    }

    func testLoopsNeverLeave() {
        for style in allMovementStyles {
            for _ in 0..<plannerRuns {
                let legs = loop(style)
                XCTAssertTrue(MovementPlanner.lureLegCount.contains(legs.count), "\(style)")
                XCTAssertFalse(legs.contains { $0.exits || $0.hides }, "\(style)")
                XCTAssertLessThanOrEqual(legs.filter(\.underCover).count, 1)
            }
        }
    }

    func testCoverIsNeverFirstOrLastStop() throws {
        var tookCover = false
        for _ in 0..<plannerRuns {
            let legs = loop(.dart)
            XCTAssertFalse(try XCTUnwrap(legs.first).underCover)
            XCTAssertFalse(try XCTUnwrap(legs.last).underCover)
            for leg in legs where leg.underCover {
                tookCover = true
                XCTAssertTrue(
                    cover.spots.contains { $0.hide == leg.destination && $0.peek == leg.peek })
                XCTAssertGreaterThanOrEqual(leg.pause, MovementPlanner.minimumCoverPause)
            }
        }
        XCTAssertTrue(tookCover)
    }

    func testFinalLureNeverTakesCover() {
        for style in allMovementStyles {
            for _ in 0..<plannerRuns {
                XCTAssertFalse(loop(style, isFinal: true).contains(where: \.underCover), "\(style)")
            }
        }
    }

    func testFinalLureFreezesLonger() {
        for _ in 0..<plannerRuns {
            let legs = loop(.flutter, isFinal: true)
            let total = legs.reduce(0) { $0 + $1.travel + $1.pause }
            let paused = legs.reduce(0) { $0 + $1.pause }
            XCTAssertEqual(paused / total, MovementPlanner.finalLurePauseFraction, accuracy: 1e-9)
        }
    }

    func testOpenStopsAvoidTheCardAndStayInView() {
        for _ in 0..<plannerRuns {
            for leg in loop(.wander) where !leg.underCover {
                XCTAssertTrue((0.05...0.95).contains(leg.destination.x), "\(leg.destination)")
                XCTAssertTrue((0.05...0.95).contains(leg.destination.y), "\(leg.destination)")
                XCTAssertFalse(cover.frame.contains(leg.destination), "\(leg.destination)")
            }
        }
    }

    func testEntersAwayFromTheCat() {
        func entry(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            MovementPlanner.lureEntryPoint(awayFrom: CGPoint(x: x, y: y), avoiding: nil)
        }
        for _ in 0..<plannerRuns {
            XCTAssertEqual(entry(0.9, 0.5).x, 0)
            XCTAssertEqual(entry(0.1, 0.5).x, 1)
            XCTAssertEqual(entry(0.5, 0.1).y, 1)
            XCTAssertEqual(entry(0.5, 0.9).y, 0)
            let anywhere = MovementPlanner.lureEntryPoint(awayFrom: nil, avoiding: cover.frame)
            XCTAssertTrue(isOnFieldEdge(anywhere), "\(anywhere)")
        }
    }

    func testExit() {
        let point = CGPoint(x: 0.2, y: 0.5)
        let fade = MovementPlanner.lureExitLegs(from: point, style: .swim)
        XCTAssertEqual(fade.count, 1)
        XCTAssertEqual(fade[0].destination, point)
        XCTAssertFalse(fade[0].exits)

        let run = MovementPlanner.lureExitLegs(from: point, style: .dart)
        XCTAssertEqual(run.map(\.destination), [CGPoint(x: 0, y: 0.5)], "Nearest edge")
        XCTAssertTrue(run[0].exits)

        for _ in 0..<plannerRuns {
            let flight = MovementPlanner.lureExitLegs(from: point, style: .peck)
            XCTAssertTrue(flight[0].exits)
            XCTAssertTrue(isOnFieldEdge(flight[0].destination), "\(flight[0].destination)")
            XCTAssertEqual(flight[0].travel, MovementPlanner.flightTravel)
        }
    }
}
