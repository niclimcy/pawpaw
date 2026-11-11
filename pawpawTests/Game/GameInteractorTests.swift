//
//  GameInteractorTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class GameInteractorTests: XCTestCase {
    private var scores: MockScoreStorage!
    private var stats: MockStatsStorage!
    private var settings: MockSettingsStorage!
    private var output: GameInteractorOutputSpy!
    private var interactor: GameInteractor!
    private var created: [GameInteractor] = []

    override func setUp() async throws {
        try await super.setUp()
        scores = MockScoreStorage()
        stats = MockStatsStorage()
        settings = MockSettingsStorage()
        output = GameInteractorOutputSpy()
        interactor = makeInteractor()
    }

    override func tearDown() async throws {
        // Stop the timers of every interactor a test made, not just the last.
        for interactor in created { interactor.stopGame() }
        created = []
        interactor = nil
        try await super.tearDown()
    }

    private func makeInteractor(
        mode: SessionMode = .standard, theme: PlayfieldTheme = .wood,
        kinds: [TargetKind] = [.mouse]
    ) -> GameInteractor {
        let interactor = GameInteractor(
            storage: scores, statsStorage: stats, settings: settings, mode: mode, theme: theme,
            tuning: .standard, enabledKinds: kinds)
        interactor.presenter = output
        created.append(interactor)
        return interactor
    }

    // MARK: Starting

    func testStartResetsAndSpawnsImmediately() {
        interactor.startGame()
        XCTAssertEqual(output.scores, [0])
        XCTAssertEqual(output.times, [60])
        XCTAssertEqual(output.hidingSpots.last?.count, PlayfieldTuning.standard.hidingSpotCount)
        XCTAssertEqual(output.spawned.count, 1)
        XCTAssertEqual(output.spawned.first?.kind, .mouse)
    }

    func testRelaxedModeHasNoTimer() {
        interactor = makeInteractor(mode: .relaxed)
        interactor.startGame()
        XCTAssertEqual(output.times, [nil])
    }

    // MARK: Catching

    func testCatchScoresOnce() throws {
        interactor.startGame()
        let target = try XCTUnwrap(output.spawned.first)

        interactor.catchTarget(id: target.id)
        interactor.catchTarget(id: target.id)

        XCTAssertEqual(output.caught.map(\.points), [TargetKind.mouse.points])
        XCTAssertEqual(output.scores, [0, 10])
    }

    func testUnknownOrExpiredTargetsCantBeCaught() throws {
        interactor.startGame()
        let target = try XCTUnwrap(output.spawned.first)
        interactor.catchTarget(id: UUID())
        interactor.expireTarget(id: target.id)
        interactor.catchTarget(id: target.id)
        XCTAssertTrue(output.caught.isEmpty)
    }

    func testNoCatchingWhilePausedOrStopped() throws {
        interactor.startGame()
        let target = try XCTUnwrap(output.spawned.first)
        interactor.pauseGame()
        interactor.catchTarget(id: target.id)
        XCTAssertTrue(output.caught.isEmpty)

        interactor.resumeGame()
        interactor.stopGame()
        interactor.catchTarget(id: target.id)
        XCTAssertTrue(output.caught.isEmpty)
    }

    func testOnScreenCrittersStillCountAfterResume() throws {
        interactor.startGame()
        let target = try XCTUnwrap(output.spawned.first)
        interactor.pauseGame()
        interactor.resumeGame()
        interactor.catchTarget(id: target.id)
        XCTAssertEqual(output.caught.count, 1)
    }

    // MARK: Pause, resume and saving

    func testPauseAndResumeAreIdempotent() {
        interactor.pauseGame()
        XCTAssertEqual(output.pauseCount, 0, "Nothing to pause before the round starts")

        interactor.startGame()
        interactor.pauseGame()
        interactor.pauseGame()
        interactor.resumeGame()
        interactor.resumeGame()
        XCTAssertEqual(output.pauseCount, 1)
        XCTAssertEqual(output.resumeCount, 1)
    }

    func testInterruptedRoundIsCountedOnce() throws {
        interactor.startGame()
        interactor.catchTarget(id: try XCTUnwrap(output.spawned.last).id)
        interactor.pauseGame()
        interactor.resumeGame()
        interactor.catchTarget(id: try XCTUnwrap(output.spawned.last).id)
        interactor.stopGame()

        XCTAssertEqual(stats.recorded.map(\.isNewRound), [true, false])
        XCTAssertEqual(stats.stats.totalRounds, 1)
        XCTAssertEqual(stats.stats.catches(of: .mouse), 2)
    }

    func testRoundsWithoutCatchesAreNotRecorded() {
        interactor.startGame()
        interactor.pauseGame()
        interactor.stopGame()
        XCTAssertTrue(stats.recorded.isEmpty)
    }

    func testStoppingTwiceDoesNotSaveTwice() throws {
        interactor.startGame()
        interactor.catchTarget(id: try XCTUnwrap(output.spawned.first).id)
        interactor.stopGame()
        interactor.stopGame()
        XCTAssertEqual(stats.recorded.count, 1)
    }

    func testNewRoundStartsAFreshStatsRound() throws {
        for _ in 0..<2 {
            interactor.startGame()
            interactor.catchTarget(id: try XCTUnwrap(output.spawned.last).id)
            interactor.stopGame()
        }
        XCTAssertEqual(stats.recorded.map(\.isNewRound), [true, true])
    }

    // MARK: Clock and results

    private func runOutClock() {
        for _ in 0..<(SessionMode.standard.duration ?? 0) { interactor.tick() }
    }

    func testRoundEndsWhenTheClockRunsOut() {
        interactor.startGame()
        for _ in 0..<59 { interactor.tick() }
        XCTAssertTrue(output.results.isEmpty)
        interactor.tick()
        XCTAssertEqual(output.results.count, 1)
        XCTAssertEqual(output.times.last, 0)
    }

    func testNoTickingWhilePaused() {
        interactor.startGame()
        interactor.pauseGame()
        runOutClock()
        XCTAssertTrue(output.results.isEmpty)
        XCTAssertEqual(output.times, [60])
    }

    func testBeatingTheBestSavesIt() throws {
        scores.scores[.standard] = 5
        interactor.startGame()
        interactor.catchTarget(id: try XCTUnwrap(output.spawned.last).id)
        runOutClock()

        XCTAssertEqual(
            output.results,
            [GameResult(score: 10, catches: 1, highScore: 10, isNewHighScore: true)])
        XCTAssertEqual(scores.scores[.standard], 10)
    }

    func testFallingShortKeepsTheOldBest() throws {
        scores.scores[.standard] = 50
        interactor.startGame()
        interactor.catchTarget(id: try XCTUnwrap(output.spawned.last).id)
        runOutClock()

        XCTAssertEqual(
            output.results,
            [GameResult(score: 10, catches: 1, highScore: 50, isNewHighScore: false)])
        XCTAssertEqual(scores.scores[.standard], 50)
    }

    func testFinishedRoundSavesCatchesAndStopsPlay() throws {
        interactor.startGame()
        let target = try XCTUnwrap(output.spawned.last)
        interactor.catchTarget(id: target.id)
        runOutClock()

        XCTAssertEqual(stats.recorded.map(\.isNewRound), [true])
        interactor.spawnTarget()
        XCTAssertEqual(output.spawned.count, 1, "Nothing spawns after the round")
        interactor.tick()
        XCTAssertEqual(output.results.count, 1, "The round only finishes once")
    }

    // MARK: Spawning

    func testSpawnsUpToTheTuningsMaxOnScreen() {
        interactor.startGame()
        for _ in 0..<5 { interactor.spawnTarget() }
        XCTAssertEqual(output.spawned.count, PlayfieldTuning.standard.maxActiveTargets)
    }

    func testCaughtOrEscapedCrittersFreeASlot() throws {
        interactor.startGame()
        interactor.spawnTarget()
        interactor.catchTarget(id: try XCTUnwrap(output.spawned.first).id)
        interactor.spawnTarget()
        interactor.expireTarget(id: try XCTUnwrap(output.spawned.last).id)
        interactor.spawnTarget()
        XCTAssertEqual(output.spawned.count, 4)
    }

    func testCatchStreakGivesTheKindANewLook() throws {
        interactor.startGame()
        for _ in 0..<GameInteractor.habituationStreak {
            interactor.catchTarget(id: try XCTUnwrap(output.spawned.last).id)
            interactor.spawnTarget()
        }
        XCTAssertEqual(
            output.spawned.map(\.variant), [.standard, .standard, .standard, .pale])
    }

    func testNewRoundForgetsTheStreak() throws {
        interactor.startGame()
        for _ in 0..<GameInteractor.habituationStreak {
            interactor.catchTarget(id: try XCTUnwrap(output.spawned.last).id)
            interactor.spawnTarget()
        }
        interactor.startGame()
        XCTAssertEqual(output.spawned.last?.variant, .standard)
    }

    // MARK: Exit tip

    func testExitTipUntilLearned() {
        XCTAssertTrue(interactor.shouldShowExitTip)
        interactor.recordExitHoldLearned()
        XCTAssertTrue(settings.hasLearnedHoldToExit)
        XCTAssertFalse(interactor.shouldShowExitTip)
    }

    // MARK: Theme filtering

    func testOnlyThemeSuitedCrittersSpawn() {
        for _ in 0..<50 {
            interactor = makeInteractor(theme: .wood, kinds: [.fish, .mouse])
            interactor.startGame()
            interactor.stopGame()
        }
        XCTAssertTrue(output.spawned.allSatisfy { $0.kind == .mouse })
    }

    func testFallsBackWhenNoEnabledCritterSuitsTheme() {
        interactor = makeInteractor(theme: .wood, kinds: [.fish])
        interactor.startGame()
        let kind = output.spawned.first?.kind
        XCTAssertNotNil(kind)
        XCTAssertNotEqual(kind, .fish)
    }
}
