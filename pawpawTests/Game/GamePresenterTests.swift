//
//  GamePresenterTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class GamePresenterTests: XCTestCase {
    private var view: GameViewSpy!
    private var interactor: GameInteractorSpy!
    private var router: GameRouterSpy!
    private var presenter: GamePresenter!

    override func setUp() async throws {
        try await super.setUp()
        view = GameViewSpy()
        interactor = GameInteractorSpy()
        router = GameRouterSpy()
        presenter = GamePresenter()
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
    }

    func testCountdownStartsTheGameOnlyWhenDone() throws {
        interactor.shouldShowExitTip = true
        presenter.viewDidBecomeReady()
        XCTAssertEqual(view.getReadyTips, [true])
        XCTAssertFalse(interactor.calls.contains("startGame"))

        try XCTUnwrap(view.getReadyCompletion)()
        XCTAssertEqual(interactor.calls, ["startGame"])
    }

    func testForwardsInputToInteractor() {
        presenter.didTapTarget(id: UUID())
        presenter.didExpireTarget(id: UUID())
        presenter.didDiscardTarget(id: UUID())
        presenter.didMissTap()
        presenter.appWillResignActive()
        presenter.appDidBecomeActive()
        presenter.viewWillDisappear()
        presenter.didFinishLureLoop(at: .zero)
        presenter.didIdleWithLure(at: .zero)
        presenter.didTapLure()
        XCTAssertEqual(
            interactor.calls,
            [
                "catchTarget", "expireTarget", "discardTarget", "missTap", "pauseGame",
                "resumeGame", "stopGame", "continueLure", "sendLureAway", "catchLure",
            ])
    }

    func testLureReadyPassesCoverAndTouch() {
        let cover = LureCover(frame: .zero, spots: [])
        presenter.didBecomeReadyForLure(cover: cover, lastTouch: CGPoint(x: 0.2, y: 0.3))
        XCTAssertEqual(interactor.lureStarts.first?.cover, cover)
        XCTAssertEqual(interactor.lureStarts.first?.touch, CGPoint(x: 0.2, y: 0.3))
    }

    func testHomeLearnsHoldStopsAndRoutes() {
        presenter.didTapHome()
        XCTAssertEqual(interactor.calls, ["recordExitHoldLearned", "stopGame"])
        XCTAssertEqual(router.navigatedHome, 1)
    }

    func testPlayAgainResetsAutoRoundsAndCountsDown() {
        presenter.didTapPlayAgain()
        XCTAssertEqual(interactor.calls, ["resetAutoRounds"])
        XCTAssertEqual(view.calls, ["hideResult", "clearTargets", "showGetReady"])
    }

    func testScoreAndTimeText() {
        presenter.didUpdateScore(35)
        presenter.didUpdateTimeRemaining(12)
        presenter.didUpdateTimeRemaining(nil)
        XCTAssertEqual(view.scoreTexts, ["Score: 35"])
        XCTAssertEqual(view.timeTexts, ["12", "∞"])
    }

    func testResultForNewBest() {
        presenter.didFinishGame(
            GameResult(score: 120, catches: 8, highScore: 120, isNewHighScore: true))
        let result = view.results.first
        XCTAssertEqual(result?.title, "New Best!")
        XCTAssertEqual(result?.symbol, "sparkles")
        XCTAssertEqual(result?.details, "You caught 8 critters\nScore: 120\nBest: 120")
        XCTAssertEqual(view.calls, ["clearTargets", "showResult", "showLureWhenReady"])
    }

    func testResultSingularCritter() {
        presenter.didFinishGame(
            GameResult(score: 5, catches: 1, highScore: 90, isNewHighScore: false))
        XCTAssertEqual(view.results.first?.title, "Time's Up!")
        XCTAssertNil(view.results.first?.symbol)
        XCTAssertEqual(view.results.first?.details, "You caught 1 critter\nScore: 5\nBest: 90")
    }

    func testLureCatchStartsNextRound() {
        presenter.didCatchLure(startsNextRound: true)
        XCTAssertEqual(
            view.calls, ["showLureCaught", "hideResult", "clearTargets", "showGetReady"])
        XCTAssertTrue(view.finalCatches.isEmpty)
    }

    func testFinalLureCatchDoesNotStartARound() {
        presenter.didCatchLure(startsNextRound: false)
        XCTAssertEqual(view.calls, ["showLureCaught", "showFinalCatch"])
        XCTAssertEqual(view.finalCatches.first?.message, "Great hunt!")
    }

    func testPauseAndResumeFreezeTargets() {
        presenter.didPause()
        presenter.didResume()
        XCTAssertEqual(view.calls, ["freezeTargets", "showPaused", "resumeTargets", "showResumed"])
    }

    func testSpawnHidingSpotsAndCatchReachView() {
        presenter.didPlaceHidingSpots([.zero])
        presenter.didSpawnTarget(
            GameTarget(id: UUID(), kind: .bug, start: .zero, legs: []))
        presenter.didCatchTarget(id: UUID(), points: 5)
        XCTAssertEqual(view.calls, ["showHidingSpots", "showTarget", "showCatch:5"])
    }

    func testNoCrashWithoutView() {
        presenter.view = nil
        presenter.viewDidBecomeReady()
        presenter.didFinishGame(
            GameResult(score: 0, catches: 0, highScore: 0, isNewHighScore: false))
        XCTAssertTrue(interactor.calls.isEmpty)
    }
}
