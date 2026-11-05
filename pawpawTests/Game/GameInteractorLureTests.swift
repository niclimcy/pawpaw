//
//  GameInteractorLureTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class GameInteractorLureTests: XCTestCase {
    private var settings: MockSettingsStorage!
    private var output: GameInteractorOutputSpy!
    private var interactor: GameInteractor!
    private var created: [GameInteractor] = []
    private let cover = LureCover(
        frame: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4),
        spots: [LureCover.Spot(hide: CGPoint(x: 0.5, y: 0.35), peek: CGPoint(x: 0.5, y: 0.28))])

    override func setUp() async throws {
        try await super.setUp()
        settings = MockSettingsStorage()
        output = GameInteractorOutputSpy()
        interactor = makeInteractor()
    }

    override func tearDown() async throws {
        for interactor in created { interactor.stopGame() }
        created = []
        interactor = nil
        try await super.tearDown()
    }

    private func makeInteractor(kinds: [TargetKind] = TargetKind.allCases) -> GameInteractor {
        let interactor = GameInteractor(
            storage: MockScoreStorage(), statsStorage: MockStatsStorage(), settings: settings,
            mode: .short, theme: .wood, enabledKinds: kinds)
        interactor.presenter = output
        created.append(interactor)
        return interactor
    }

    func testNoLureDuringARound() {
        interactor.startGame()
        interactor.startLure(cover: cover, awayFrom: nil)
        interactor.catchLure()
        XCTAssertTrue(output.lureMoves.isEmpty)
        XCTAssertTrue(output.lureCatches.isEmpty)
    }

    func testLureIsNeverALaserAndChangesEachTime() {
        var kinds: [TargetKind] = []
        for _ in 0..<100 {
            interactor.startLure(cover: cover, awayFrom: nil)
            kinds.append(output.lureMoves.last!.target.kind)
            interactor.catchLure()
        }
        XCTAssertFalse(kinds.contains(.laser))
        XCTAssertFalse(kinds.contains(.fish), "Fish don't appear on wood")
        for (previous, next) in zip(kinds, kinds.dropFirst()) {
            XCTAssertNotEqual(previous, next, "A new look every results screen")
        }
    }

    /// Profiles saved before `isPlayable` ruled it out may still have only the laser.
    func testLegacyLaserOnlyCatGetsTheLaserNotADisabledCritter() {
        interactor = makeInteractor(kinds: [.laser])
        interactor.startLure(cover: cover, awayFrom: nil)
        XCTAssertEqual(output.lureMoves.last?.target.kind, .laser)
    }

    func testLureIsAlwaysAnEnabledCritter() {
        let enabled: Set<TargetKind> = [.laser, .bug, .ribbon]
        interactor = makeInteractor(kinds: Array(enabled))
        for _ in 0..<50 {
            interactor.startLure(cover: cover, awayFrom: nil)
            interactor.catchLure()
        }
        let kinds = Set(output.lureMoves.map(\.target.kind))
        XCTAssertTrue(kinds.isSubset(of: enabled), "\(kinds)")
        XCTAssertFalse(kinds.contains(.laser), "The laser only roams when nothing else can")
    }

    func testRelayoutKeepsTheSameCritter() throws {
        interactor.startLure(cover: cover, awayFrom: nil)
        let first = try XCTUnwrap(output.lureMoves.last?.target)
        interactor.startLure(cover: cover, awayFrom: CGPoint(x: 0.9, y: 0.5))
        let second = try XCTUnwrap(output.lureMoves.last?.target)
        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(first.kind, second.kind)
    }

    func testContinueAndSendAway() throws {
        interactor.continueLure(from: CGPoint(x: 0.5, y: 0.5))
        XCTAssertTrue(output.lureMoves.isEmpty, "No lure yet")

        interactor.startLure(cover: cover, awayFrom: nil)
        interactor.continueLure(from: CGPoint(x: 0, y: 1))
        let looped = try XCTUnwrap(output.lureMoves.last)
        XCTAssertFalse(looped.isLeaving)
        XCTAssertEqual(looped.target.leadIn, 0)
        XCTAssertTrue((0.01...0.99).contains(looped.target.start.x), "Kept inside the border")
        XCTAssertTrue((0.01...0.99).contains(looped.target.start.y))

        interactor.sendLureAway(from: CGPoint(x: 0.2, y: 0.5))
        let leaving = try XCTUnwrap(output.lureMoves.last)
        XCTAssertTrue(leaving.isLeaving)
        XCTAssertEqual(leaving.target.id, looped.target.id)

        interactor.catchLure()
        XCTAssertEqual(output.lureCatches.count, 1, "It can still be caught on the way out")
    }

    func testCatchingWithoutALureDoesNothing() {
        interactor.catchLure()
        XCTAssertTrue(output.lureCatches.isEmpty)
    }

    private func catchLures(_ count: Int) -> [Bool] {
        for _ in 0..<count {
            interactor.startLure(cover: cover, awayFrom: nil)
            interactor.catchLure()
        }
        return output.lureCatches
    }

    func testKeepPlayingAlwaysStartsAnotherRound() {
        settings.afterRound = .keepPlaying
        XCTAssertEqual(catchLures(10), Array(repeating: true, count: 10))
    }

    func testStopOnlyGivesTheFinalCatch() {
        settings.afterRound = .stop
        XCTAssertEqual(catchLures(2), [false, false])
    }

    func testLimitedStartsThreeRoundsThenFinal() {
        settings.afterRound = .limited
        XCTAssertEqual(catchLures(5), [true, true, true, false, false])
    }

    func testOwnerStartingARoundResetsTheLimit() {
        settings.afterRound = .limited
        _ = catchLures(3)
        interactor.resetAutoRounds()
        XCTAssertEqual(catchLures(1).last, true)
    }

    func testFinalLureNeverTakesCover() {
        settings.afterRound = .stop
        for _ in 0..<100 {
            interactor.startLure(cover: cover, awayFrom: nil)
            XCTAssertFalse(output.lureMoves.last!.target.legs.contains(where: \.underCover))
            interactor.catchLure()
        }
    }
}
