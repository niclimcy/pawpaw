//
//  HomeTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class HomeInteractorTests: XCTestCase {
    private var profiles: MockProfileStorage!
    private var settings: MockSettingsStorage!
    private var scores: MockScoreStorage!
    private var stats: MockStatsStorage!
    private var output: HomeInteractorOutputSpy!
    private var interactor: HomeInteractor!
    private var requestedIDs: [UUID] = []

    override func setUp() async throws {
        try await super.setUp()
        profiles = MockProfileStorage(profiles: [CatProfile(name: "Tom"), CatProfile(name: "Luna")])
        settings = MockSettingsStorage()
        scores = MockScoreStorage()
        stats = MockStatsStorage()
        output = HomeInteractorOutputSpy()
        interactor = HomeInteractor(
            profileStorage: profiles, settings: settings,
            makeScoreStorage: { [unowned self] in
                self.requestedIDs.append($0)
                return self.scores
            },
            makeStatsStorage: { [unowned self] _ in self.stats })
        interactor.presenter = output
    }

    func testFetchStateForActiveCat() throws {
        scores.scores[.standard] = 80
        stats.stats.record(catches: [.bird: 2])
        profiles.setActive(profiles.profiles[1].id)

        interactor.fetchState()

        let state = try XCTUnwrap(output.states.last)
        XCTAssertEqual(state.profile.name, "Luna")
        XCTAssertEqual(state.mode, .standard)
        XCTAssertEqual(state.highScore, 80)
        XCTAssertEqual(state.favorite, .bird)
        XCTAssertEqual(requestedIDs, [profiles.profiles[1].id], "Scores for the active cat")
    }

    func testRelaxedModeHasNoHighScore() {
        interactor.selectMode(.relaxed)
        XCTAssertEqual(settings.selectedMode, .relaxed)
        XCTAssertNil(output.states.last?.highScore)
        XCTAssertEqual(interactor.selectedMode, .relaxed)
    }

    func testSelectionsAreSavedAndRefetched() {
        interactor.selectTheme(.snow)
        interactor.selectAfterRound(.stop)
        XCTAssertEqual(settings.selectedTheme, .snow)
        XCTAssertEqual(settings.afterRound, .stop)
        XCTAssertEqual(output.states.count, 2)
        XCTAssertEqual(output.states.last?.theme, .snow)
        XCTAssertEqual(output.states.last?.afterRound, .stop)
    }
}

@MainActor
final class HomePresenterTests: XCTestCase {
    private var view: HomeViewSpy!
    private var interactor: HomeInteractorSpy!
    private var router: HomeRouterSpy!
    private var presenter: HomePresenter!

    override func setUp() async throws {
        try await super.setUp()
        view = HomeViewSpy()
        interactor = HomeInteractorSpy()
        router = HomeRouterSpy()
        presenter = HomePresenter()
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
    }

    func testForwardsSelections() {
        presenter.viewWillAppear()
        presenter.didSelectMode(.short)
        presenter.didSelectTheme(.pond)
        presenter.didSelectAfterRound(.limited)
        XCTAssertEqual(
            interactor.calls,
            ["fetchState", "selectMode:short", "selectTheme:pond", "selectAfterRound:limited"])
    }

    func testRouting() {
        presenter.didTapPlay()
        presenter.didRequestStats()
        presenter.didTapProfile()
        XCTAssertEqual(router.gameModes, [.long])
        XCTAssertEqual(router.statsCount, 1)
        XCTAssertEqual(router.profilesCount, 1)
    }

    func testPlayWithoutInteractorDoesNothing() {
        presenter.interactor = nil
        presenter.didTapPlay()
        XCTAssertTrue(router.gameModes.isEmpty)
    }

    private func fetch(mode: SessionMode, favorite: TargetKind?) {
        presenter.didFetchState(
            mode: mode, theme: .grass, afterRound: .limited,
            highScore: mode.hasHighScore ? 40 : nil,
            profile: CatProfile(name: "Tom", face: .gray), favorite: favorite)
    }

    func testShowsState() {
        fetch(mode: .standard, favorite: .butterfly)
        XCTAssertEqual(view.modes, [.standard])
        XCTAssertEqual(view.themes, [.grass])
        XCTAssertEqual(view.afterRounds.first?.mode, .limited)
        XCTAssertEqual(view.afterRounds.first?.isAvailable, true)
        XCTAssertEqual(view.highScores, [40])
        XCTAssertEqual(view.profiles.first?.name, "Tom")
        XCTAssertEqual(view.profiles.first?.face, .gray)
        XCTAssertEqual(view.profiles.first?.favorite, "Loves butterflies")
    }

    func testUntimedModeHidesAfterRoundAndBest() {
        fetch(mode: .relaxed, favorite: nil)
        XCTAssertEqual(view.afterRounds.first?.isAvailable, false)
        XCTAssertEqual(view.highScores, [nil])
        XCTAssertEqual(view.profiles.first?.favorite, nil)
    }

    func testScreenNoteFollowsTuning() {
        presenter.tuning = .standard
        fetch(mode: .short, favorite: nil)
        presenter.tuning = .pocket
        fetch(mode: .short, favorite: nil)
        XCTAssertEqual(view.notes, [nil, "Plays best on a bigger screen"])
    }
}
