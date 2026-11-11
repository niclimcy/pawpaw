//
//  MovementPlannerTests.swift
//  pawpawTests
//

import CoreGraphics
import XCTest

@testable import pawpaw

let plannerRuns = 300

@MainActor
var allMovementStyles: [MovementStyle] {
    TargetKind.allCases.map(\.movementStyle)
}

func isOnFieldEdge(_ point: CGPoint) -> Bool {
    point.x == 0 || point.x == 1 || point.y == 0 || point.y == 1
}

func isInField(_ point: CGPoint) -> Bool {
    (0...1).contains(point.x) && (0...1).contains(point.y)
}

/// The planner is random, so each property is checked over many runs.
@MainActor
final class MovementPlannerTests: XCTestCase {
    func testLeadIn() {
        XCTAssertEqual(MovementPlanner.leadIn(for: .swim), 0)
        for _ in 0..<plannerRuns {
            XCTAssertTrue(MovementPlanner.leadInRange.contains(MovementPlanner.leadIn(for: .dart)))
        }
    }

    func testHidingSpotsCountAndBounds() {
        XCTAssertTrue(MovementPlanner.hidingSpots(count: 0).isEmpty)
        for _ in 0..<plannerRuns {
            let spots = MovementPlanner.hidingSpots(count: 2)
            XCTAssertEqual(spots.count, 2)
            for spot in spots {
                XCTAssertTrue(
                    MovementPlanner.hidingSpotXRange.contains(spot.x)
                        && MovementPlanner.hidingSpotYRange.contains(spot.y))
            }
        }
    }

    func testRandomEdgePointIsOnTheFieldEdge() {
        for _ in 0..<plannerRuns {
            let point = MovementPlanner.randomEdgePoint()
            XCTAssertTrue(isInField(point), "\(point)")
            XCTAssertTrue(isOnFieldEdge(point), "\(point)")
        }
    }

    func testRandomEdgePointReachesEveryEdge() {
        let points = (0..<plannerRuns).map { _ in MovementPlanner.randomEdgePoint() }
        XCTAssertTrue(points.contains { $0.x == 0 })
        XCTAssertTrue(points.contains { $0.x == 1 })
        XCTAssertTrue(points.contains { $0.y == 0 })
        XCTAssertTrue(points.contains { $0.y == 1 })
    }

    func testRandomInnerPointStaysInsideTheInnerRange() {
        for _ in 0..<plannerRuns {
            let point = MovementPlanner.randomInnerPoint()
            XCTAssertTrue(MovementPlanner.innerRange.contains(point.x), "\(point)")
            XCTAssertTrue(MovementPlanner.innerRange.contains(point.y), "\(point)")
        }
    }

    func testEveryLegStaysInTheField() {
        for style in allMovementStyles {
            for _ in 0..<plannerRuns {
                let legs = MovementPlanner.legs(
                    from: CGPoint(x: 0, y: 0.5), style: style, duration: 5,
                    coverSpots: [CGPoint(x: 0.5, y: 0.5)])
                for leg in legs {
                    XCTAssertTrue(isInField(leg.destination), "\(style): \(leg.destination)")
                    XCTAssertGreaterThanOrEqual(leg.travel, 0, "\(style)")
                    XCTAssertGreaterThanOrEqual(leg.pause, 0, "\(style)")
                }
            }
        }
    }

    func testEdgeCrittersExitOnceAndSurfacersDont() throws {
        for style in allMovementStyles {
            for _ in 0..<plannerRuns {
                let legs = MovementPlanner.legs(
                    from: CGPoint(x: 0.5, y: 0.5), style: style, duration: 5)
                let last = try XCTUnwrap(legs.last)
                if style.surfaces {
                    XCTAssertFalse(legs.contains { $0.exits }, "\(style) fades out in place")
                } else {
                    XCTAssertTrue(last.exits, "\(style)")
                    XCTAssertTrue(isOnFieldEdge(last.destination), "\(style): \(last.destination)")
                    XCTAssertEqual(legs.filter(\.exits).count, 1, "\(style)")
                }
            }
        }
    }

    func testLegCountMatchesStyle() {
        for style in allMovementStyles where !style.fliesOff {
            for _ in 0..<plannerRuns {
                let legs = MovementPlanner.legs(from: .zero, style: style, duration: 5)
                let roaming = legs.filter { !$0.exits }.count
                XCTAssertTrue(style.legCount.contains(roaming), "\(style): \(roaming) legs")
            }
        }
    }

    /// Fliers may leave early, which only shortens the path.
    func testFliersNeverOverrunTheirLifetime() {
        for _ in 0..<plannerRuns {
            let legs = MovementPlanner.legs(from: .zero, style: .peck, duration: 6)
            let roaming = legs.filter { !$0.exits }
            XCTAssertLessThanOrEqual(roaming.reduce(0) { $0 + $1.travel + $1.pause }, 6 + 1e-9)
            XCTAssertGreaterThanOrEqual(roaming.count, 3)
        }
    }

    func testTimeOnFieldMatchesDurationUnlessCoverLengthensIt() {
        for style in allMovementStyles where !style.fliesOff {
            for _ in 0..<plannerRuns {
                let legs = MovementPlanner.legs(
                    from: .zero, style: style, duration: 5, coverSpots: [CGPoint(x: 0.5, y: 0.5)])
                let roaming = legs.filter { !$0.exits }
                let total = roaming.reduce(0) { $0 + $1.travel + $1.pause }
                if roaming.contains(where: \.underCover) {
                    XCTAssertGreaterThanOrEqual(total, 5 - 1e-9, "\(style)")
                } else {
                    XCTAssertEqual(total, 5, accuracy: 1e-9, "\(style)")
                }
            }
        }
    }

    func testCoverRules() {
        let spot = CGPoint(x: 0.5, y: 0.5)
        var tookCover = false
        for style in allMovementStyles {
            for _ in 0..<plannerRuns {
                let legs = MovementPlanner.legs(
                    from: .zero, style: style, duration: 8, coverSpots: [spot])
                let covered = legs.filter(\.underCover)
                XCTAssertLessThanOrEqual(covered.count, 1, "\(style)")
                if style.coverChance == 0 { XCTAssertTrue(covered.isEmpty, "\(style)") }
                for leg in covered {
                    tookCover = true
                    XCTAssertEqual(leg.destination, spot)
                    XCTAssertGreaterThanOrEqual(leg.pause, MovementPlanner.minimumCoverPause)
                    XCTAssertFalse(leg.hides, "Can't run off-screen while under cover")
                }
            }
        }
        XCTAssertTrue(tookCover, "Some critter should have used the spot")
    }

    func testNoCoverWithoutSpots() {
        for style in allMovementStyles {
            for _ in 0..<plannerRuns {
                let legs = MovementPlanner.legs(from: .zero, style: style, duration: 8)
                XCTAssertFalse(legs.contains(where: \.underCover), "\(style)")
            }
        }
    }

    func testHidesOnlyDuringLongFreezes() {
        for style in allMovementStyles {
            for _ in 0..<plannerRuns {
                for leg in MovementPlanner.legs(from: .zero, style: style, duration: 8)
                where leg.hides {
                    XCTAssertGreaterThanOrEqual(leg.pause, MovementPlanner.minimumHidePause)
                    XCTAssertGreaterThan(style.hideChance, 0, "\(style)")
                }
            }
        }
    }
}
