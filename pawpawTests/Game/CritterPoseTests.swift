//
//  CritterPoseTests.swift
//  pawpawTests
//

import SpriteKit
import XCTest

@testable import pawpaw

@MainActor
final class CritterPoseTests: XCTestCase {
    private let geometry = PlayfieldGeometry(
        size: CGSize(width: 1000, height: 800), topInset: 100, tuning: .standard)

    private func plan(_ kind: TargetKind, legs: [PathLeg], leadIn: TimeInterval = 0) throws
        -> CritterActions.Plan
    {
        let target = GameTarget(
            id: UUID(), kind: kind, start: CGPoint(x: 0, y: 0.5), legs: legs, leadIn: leadIn)
        return try XCTUnwrap(CritterActions.plan(for: target, in: geometry))
    }

    private func leg(
        _ x: CGFloat, travel: TimeInterval, pause: TimeInterval = 0, exits: Bool = false,
        flies: Bool = false
    ) -> PathLeg {
        PathLeg(
            destination: CGPoint(x: x, y: 0.5), travel: travel, pause: pause, hides: false,
            exits: exits, flies: flies)
    }

    // MARK: Artwork

    func testPoseArtworkExistsInAssetCatalog() {
        for kind in TargetKind.allCases {
            let names = [
                kind.movingImageName, kind.alternateMovingImageName, kind.flyingImageName,
            ]
            for name in names.compactMap({ $0 }) {
                XCTAssertNotNil(UIImage(named: name), "Missing asset \(name)")
            }
        }
    }

    func testFieldArtworkExistsInAssetCatalog() {
        for kind in TargetKind.allCases {
            XCTAssertNotNil(UIImage(named: kind.fieldImageName), "Missing \(kind.fieldImageName)")
        }
    }

    func testOnlyTheRibbonRipples() throws {
        for kind in TargetKind.allCases {
            let plan = try plan(kind, legs: [leg(0.3, travel: 1), leg(0.6, travel: 1)])
            XCTAssertEqual(plan.ripples, kind == .ribbon, "\(kind)")
        }
    }

    func testPosesAreTheRestingSize() throws {
        let critter = try XCTUnwrap(PlayfieldTextures.critter(.bug, variant: .dusk, size: 90))
        for pose in PlayfieldTextures.CritterPose.allCases {
            let texture = try XCTUnwrap(critter.texture(for: pose), "\(pose)")
            XCTAssertEqual(texture.size(), critter.texture.size(), "\(pose)")
        }
        XCTAssertTrue(critter.texture(for: .rest) === critter.texture)
    }

    func testCritterOnlyHasThePosesItHasArtworkFor() throws {
        let mouse = try XCTUnwrap(PlayfieldTextures.critter(.mouse, variant: .standard, size: 90))
        XCTAssertEqual(Set(mouse.poses.keys), [.moving, .movingAlternate])
        let bird = try XCTUnwrap(PlayfieldTextures.critter(.bird, variant: .standard, size: 90))
        XCTAssertEqual(Set(bird.poses.keys), [.flying])
    }

    func testCritterWithoutMovingArtworkOnlyRests() throws {
        let critter = try XCTUnwrap(
            PlayfieldTextures.critter(.feather, variant: .standard, size: 90))
        XCTAssertTrue(critter.poses.isEmpty)
        XCTAssertNil(critter.texture(for: .moving))
    }

    func testCaughtCritterOnlyRests() throws {
        let critter = try XCTUnwrap(
            PlayfieldTextures.critter(.mouse, variant: .standard, size: 90, style: .caught))
        XCTAssertTrue(critter.poses.isEmpty)
    }

    // MARK: Cues

    func testWalkerStridesOnlyWhileTravelling() throws {
        let plan = try plan(
            .mouse, legs: [leg(0.3, travel: 1, pause: 2), leg(0.6, travel: 0.5)], leadIn: 0.4)
        XCTAssertEqual(plan.poses.map(\.start), [0.4, 3.4])
        XCTAssertEqual(plan.poses.map(\.duration), [1, 0.5])
        XCTAssertEqual(plan.poses.first?.poses, [.moving, .rest, .movingAlternate, .rest])
    }

    func testLadybugFliesInWalksThenFliesOut() throws {
        let plan = try plan(
            .bug,
            legs: [
                leg(0.3, travel: 0.6, pause: 1, flies: true), leg(0.5, travel: 1, pause: 1),
                leg(1.2, travel: 0.8, exits: true, flies: true),
            ])
        XCTAssertEqual(
            plan.poses.map(\.poses), [[.flying], [.moving, .movingAlternate], [.flying]])
        XCTAssertEqual(plan.poses.map(\.start), [0, 1.6, 3.6])
    }

    func testFlyingLegsBeatTheWingsInsteadOfStriding() throws {
        let flying = try plan(.bug, legs: [leg(0.3, travel: 0.6, flies: true)])
        let walking = try plan(.bug, legs: [leg(0.3, travel: 0.6)])
        // SpriteKit keeps durations as Float.
        XCTAssertEqual(flying.wings.first?.duration ?? 0, 0.6, accuracy: 1e-6)
        XCTAssertEqual(walking.wings.first?.duration ?? 0, 0, accuracy: 1e-6)
        XCTAssertEqual(flying.jiggle.first?.duration ?? 0, 0, accuracy: 1e-6)
    }

    func testStepsKeepPaceWithTheGround() throws {
        let fast = try plan(.mouse, legs: [leg(0.9, travel: 0.4, pause: 1), leg(0.95, travel: 2)])
        let frames = fast.poses.map(\.frameTime)
        XCTAssertEqual(frames.count, 2)
        XCTAssertEqual(frames[0], 0.04, accuracy: 1e-9, "a full run steps at the quickest pace")
        XCTAssertEqual(frames[1], 0.12, accuracy: 1e-9, "a creep steps at most 3x slower")
    }

    func testPeekingOutFromCoverTakesSteps() throws {
        var under = leg(0.5, travel: 1, pause: 2)
        under.underCover = true
        under.peek = CGPoint(x: 0.6, y: 0.5)
        let plan = try plan(.mouse, legs: [under, leg(0.8, travel: 1)])
        // The walk in, out and back twice, then the walk on.
        assertTimes(plan.poses.map(\.start), [0, 1, 1.6, 1.9, 2.3, 3])
        for cue in plan.poses {
            XCTAssertLessThanOrEqual(
                cue.frameTime * Double(cue.poses.count), cue.duration + 1e-9,
                "a whole step fits each move")
        }
    }

    func testDuckingOffTheEdgeTakesSteps() throws {
        let hide = PathLeg(
            destination: CGPoint(x: 0.1, y: 0.5), travel: 1, pause: 2, hides: true)
        let plan = try plan(.lizard, legs: [hide, leg(0.5, travel: 1)])
        assertTimes(plan.poses.map(\.start), [0, 1, 1 + 2 - MovementPlanner.hideTravel, 3])
    }

    private func assertTimes(
        _ actual: [TimeInterval], _ expected: [TimeInterval], line: UInt = #line
    ) {
        XCTAssertEqual(actual.count, expected.count, "\(actual)", line: line)
        for (a, e) in zip(actual, expected) {
            XCTAssertEqual(a, e, accuracy: 1e-9, "\(actual)", line: line)
        }
    }

    func testCricketHoldsItsJumpForEachHop() throws {
        let plan = try plan(.cricket, legs: [leg(0.3, travel: 0.6, pause: 1)])
        XCTAssertEqual(
            plan.poses,
            [CritterActions.PoseCue(start: 0, duration: 0.6, poses: [.moving], frameTime: 0.6)])
    }

    func testBirdSpreadsItsWingsOnlyToFlyOff() throws {
        let plan = try plan(
            .bird,
            legs: [leg(0.3, travel: 1, pause: 1), leg(1.2, travel: 0.8, exits: true, flies: true)])
        XCTAssertEqual(
            plan.poses,
            [CritterActions.PoseCue(start: 2, duration: 0.8, poses: [.flying], frameTime: 0.8)])
    }

    func testFishSwimsForItsWholeLifetime() throws {
        let plan = try plan(.fish, legs: [leg(0.3, travel: 1, pause: 1), leg(0.6, travel: 1)])
        let cue = try XCTUnwrap(plan.poses.first)
        XCTAssertEqual(plan.poses.count, 1)
        XCTAssertEqual(cue.start + cue.duration, 3, accuracy: 1e-9)
        XCTAssertEqual(cue.poses, [.movingAlternate, .rest, .moving, .rest])
        // The body sways furthest a quarter and three quarters of the way through each stroke,
        // so each swept tail is shown either side of those peaks.
        let stroke = cue.frameTime * Double(cue.poses.count)
        XCTAssertEqual(cue.start + cue.frameTime / 2, stroke / 4, accuracy: 1e-9)
    }

    func testCritterWithoutMovingArtworkHasNoCues() throws {
        let plan = try plan(.ribbon, legs: [leg(0.3, travel: 1), leg(0.6, travel: 1)])
        XCTAssertTrue(plan.poses.isEmpty)
    }
}
