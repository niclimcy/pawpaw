//
//  EntityTests.swift
//  pawpawTests
//

import UIKit
import XCTest

@testable import pawpaw

@MainActor
final class EntityTests: XCTestCase {
    // MARK: SessionMode

    func testSessionDurations() {
        XCTAssertEqual(SessionMode.short.duration, 30)
        XCTAssertEqual(SessionMode.standard.duration, 60)
        XCTAssertEqual(SessionMode.long.duration, 120)
        XCTAssertNil(SessionMode.relaxed.duration)
    }

    func testOnlyTimedModesHaveHighScores() {
        for mode in SessionMode.allCases {
            XCTAssertEqual(mode.hasHighScore, mode.duration != nil, "\(mode)")
        }
    }

    // MARK: TargetKind

    func testThemeExclusiveCritters() {
        XCTAssertTrue(TargetKind.fish.canAppear(on: .pond))
        XCTAssertFalse(TargetKind.fish.canAppear(on: .grass))
        XCTAssertTrue(TargetKind.lizard.canAppear(on: .grass))
        XCTAssertFalse(TargetKind.lizard.canAppear(on: .snow))
        for theme in PlayfieldTheme.allCases {
            XCTAssertTrue(TargetKind.mouse.canAppear(on: theme))
        }
    }

    func testEveryThemeHasSpawnableCritters() {
        for theme in PlayfieldTheme.allCases {
            XCTAssertFalse(TargetKind.allCases.filter { $0.canAppear(on: theme) }.isEmpty)
        }
    }

    func testKindTuningIsSane() {
        for kind in TargetKind.allCases {
            XCTAssertGreaterThan(kind.points, 0, "\(kind)")
            XCTAssertGreaterThan(kind.weight, 0, "\(kind)")
            XCTAssertGreaterThan(kind.lifetimeRange.lowerBound, 0, "\(kind)")
            XCTAssertFalse(kind.pluralName.isEmpty, "\(kind)")
            XCTAssertTrue(kind.imageName.hasPrefix("critter_"), "\(kind)")
        }
    }

    func testCritterImagesExistInAssetCatalog() {
        for kind in TargetKind.allCases {
            XCTAssertNotNil(UIImage(named: kind.imageName), "Missing asset \(kind.imageName)")
        }
        for face in CatFace.allCases {
            XCTAssertNotNil(UIImage(named: face.imageName), "Missing asset \(face.imageName)")
        }
    }

    func testOnlyLaserGlowsAndIgnoresHeading() {
        for kind in TargetKind.allCases {
            XCTAssertEqual(kind.glows, kind == .laser)
            XCTAssertEqual(kind.turnsToFaceMovement, kind != .laser)
        }
    }

    // MARK: AfterRoundMode

    func testAfterRoundContinues() {
        XCTAssertTrue(AfterRoundMode.keepPlaying.continues(afterAutoRounds: 100))
        XCTAssertFalse(AfterRoundMode.stop.continues(afterAutoRounds: 0))
        XCTAssertTrue(AfterRoundMode.limited.continues(afterAutoRounds: 0))
        XCTAssertTrue(
            AfterRoundMode.limited.continues(afterAutoRounds: AfterRoundMode.roundLimit - 1))
        XCTAssertFalse(AfterRoundMode.limited.continues(afterAutoRounds: AfterRoundMode.roundLimit))
    }

    func testLimitedTitleMentionsLimit() {
        XCTAssertEqual(AfterRoundMode.limited.title, "3 rounds")
    }

    // MARK: CritterVariant

    func testVariantsCycle() {
        let count = CritterVariant.allCases.count
        XCTAssertEqual(CritterVariant.cycled(0), .standard)
        XCTAssertEqual(CritterVariant.cycled(1), .pale)
        XCTAssertEqual(CritterVariant.cycled(count), .standard)
        XCTAssertEqual(CritterVariant.cycled(count + 3), CritterVariant.cycled(3))
    }

    func testOnlyStandardHasNoTint() {
        for variant in CritterVariant.allCases {
            XCTAssertEqual(variant.tint == nil, variant == .standard)
            if let tint = variant.tint {
                XCTAssertTrue((0...1).contains(tint.amount))
            }
        }
    }

    // MARK: GameTarget

    func testLifetimeIncludesLeadInTravelAndPauses() {
        let target = GameTarget(
            id: UUID(), kind: .mouse, start: .zero,
            legs: [
                PathLeg(destination: .zero, travel: 1, pause: 0.5, hides: false),
                PathLeg(destination: .zero, travel: 2, pause: 0, hides: false),
            ],
            leadIn: 0.25)
        XCTAssertEqual(target.lifetime, 3.75, accuracy: 1e-9)
    }

    // MARK: PlayfieldTheme / PlayfieldTuning

    func testCoverRules() {
        XCTAssertTrue(PlayfieldTheme.pond.allowsCover(for: .swim))
        XCTAssertFalse(PlayfieldTheme.pond.allowsCover(for: .dart))
        XCTAssertTrue(PlayfieldTheme.wood.allowsCover(for: .dart))
        XCTAssertFalse(PlayfieldTheme.wood.allowsCover(for: .swim))
        for theme in PlayfieldTheme.allCases {
            XCTAssertFalse(theme.allowsCover(for: .flutter), "No cover chance means no cover")
        }
    }

    func testTuningPaceScalesLifetime() {
        XCTAssertEqual(PlayfieldTuning.standard.lifetime(for: 5), 5, accuracy: 1e-9)
        XCTAssertEqual(PlayfieldTuning.pocket.lifetime(for: 8.5), 10, accuracy: 1e-9)
    }

    func testPocketFlags() {
        XCTAssertTrue(PlayfieldTuning.pocket.isPocket)
        XCTAssertFalse(PlayfieldTuning.standard.isPocket)
        XCTAssertNil(PlayfieldTuning.standard.screenNote)
        XCTAssertNotNil(PlayfieldTuning.pocket.screenNote)
    }

    func testCurrentTuningMatchesDevice() {
        let expected: PlayfieldTuning =
            UIDevice.current.userInterfaceIdiom == .phone ? .pocket : .standard
        XCTAssertEqual(PlayfieldTuning.current, expected)
    }
}
