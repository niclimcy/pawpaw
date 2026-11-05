//
//  StatsTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class StatsInteractorTests: XCTestCase {
    func testFetchesBestScoresForTimedModesOnly() throws {
        let scores = MockScoreStorage()
        scores.scores = [.short: 10, .standard: 20, .long: 30, .relaxed: 99]
        let stats = MockStatsStorage()
        stats.stats.record(catches: [.bug: 2])
        let profile = CatProfile(name: "Tom")
        let output = StatsInteractorOutputSpy()
        let interactor = StatsInteractor(
            profile: profile, scoreStorage: scores, statsStorage: stats)
        interactor.presenter = output

        interactor.fetchStats()

        let fetched = try XCTUnwrap(output.fetched.last)
        XCTAssertEqual(fetched.bestScores.map(\.mode), [.short, .standard, .long])
        XCTAssertEqual(fetched.bestScores.map(\.score), [10, 20, 30])
        XCTAssertEqual(fetched.stats, stats.stats)
        XCTAssertEqual(fetched.profile, profile)
    }

    func testResetClearsStatsButKeepsBestScores() throws {
        let scores = MockScoreStorage()
        scores.scores = [.short: 10]
        let stats = MockStatsStorage()
        stats.stats.record(catches: [.bug: 2])
        let output = StatsInteractorOutputSpy()
        let interactor = StatsInteractor(
            profile: CatProfile(name: "Tom"), scoreStorage: scores, statsStorage: stats)
        interactor.presenter = output

        interactor.resetStats()

        XCTAssertEqual(stats.resetCount, 1)
        let fetched = try XCTUnwrap(output.fetched.last)
        XCTAssertEqual(fetched.stats, PlayStats())
        XCTAssertEqual(fetched.bestScores.first?.score, 10)
    }
}

@MainActor
final class StatsPresenterTests: XCTestCase {
    private var view: StatsViewSpy!
    private var interactor: StatsInteractorSpy!
    private var router: StatsRouterSpy!
    private var presenter: StatsPresenter!

    override func setUp() async throws {
        try await super.setUp()
        view = StatsViewSpy()
        interactor = StatsInteractorSpy()
        router = StatsRouterSpy()
        presenter = StatsPresenter()
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
    }

    func testForwardsActions() {
        presenter.viewWillAppear()
        presenter.didConfirmReset()
        presenter.didTapBack()
        XCTAssertEqual(interactor.calls, ["fetchStats", "resetStats"])
        XCTAssertEqual(router.backCount, 1)
    }

    func testEmptyStats() throws {
        presenter.didFetchStats(PlayStats(), bestScores: [], profile: CatProfile(name: "Tom"))
        let model = try XCTUnwrap(view.viewModels.last)
        XCTAssertEqual(model.title, "Tom's Stats")
        XCTAssertEqual(
            model.rounds,
            StatsViewModel.Metric(value: "0", caption: "Rounds", accessibilityLabel: "no rounds"))
        XCTAssertEqual(model.catches.accessibilityLabel, "no catches")
        XCTAssertNil(model.favoriteImageName)
        XCTAssertEqual(model.favoriteAccessibilityLabel, "No favorite catch yet")
        XCTAssertEqual(model.critters.count, TargetKind.allCases.count)
        XCTAssertTrue(model.critters.allSatisfy(\.isEmpty))
        XCTAssertEqual(model.days.count, 7)
        XCTAssertTrue(model.bestScores.isEmpty)
    }

    func testSingularAndPluralLabels() throws {
        var stats = PlayStats()
        stats.record(catches: [.laser: 1])
        presenter.didFetchStats(
            stats, bestScores: [(.short, 25), (.long, 0)], profile: CatProfile(name: "Luna"))

        let model = try XCTUnwrap(view.viewModels.last)
        XCTAssertEqual(
            model.rounds,
            StatsViewModel.Metric(value: "1", caption: "Round", accessibilityLabel: "1 round"))
        XCTAssertEqual(
            model.catches,
            StatsViewModel.Metric(value: "1", caption: "Catch", accessibilityLabel: "1 catch"))
        XCTAssertEqual(model.favoriteImageName, "critter_laser")
        XCTAssertEqual(model.favoriteAccessibilityLabel, "Favorite catch: laser dots")

        let laserRow = try XCTUnwrap(model.critters.first { $0.imageName == "critter_laser" })
        XCTAssertEqual(laserRow.catches, "1")
        XCTAssertFalse(laserRow.isEmpty)
        XCTAssertEqual(laserRow.accessibilityLabel, "Laser Dots: 1 catch")

        XCTAssertEqual(model.days.last?.rounds, 1, "Today is the last bar")
        XCTAssertEqual(
            model.bestScores,
            [
                StatsViewModel.Metric(
                    value: "25", caption: "30s", accessibilityLabel: "Best score, 30s: 25"),
                StatsViewModel.Metric(
                    value: "0", caption: "2 min", accessibilityLabel: "Best score, 2 min: 0"),
            ])
    }

    func testPluralCatches() throws {
        var stats = PlayStats()
        stats.record(catches: [.mouse: 3])
        stats.record(catches: [.mouse: 1])
        presenter.didFetchStats(stats, bestScores: [], profile: CatProfile(name: "Tom"))
        let model = try XCTUnwrap(view.viewModels.last)
        XCTAssertEqual(model.rounds.accessibilityLabel, "2 rounds")
        XCTAssertEqual(model.catches.caption, "Catches")
        XCTAssertEqual(model.catches.accessibilityLabel, "4 catches")
    }
}
