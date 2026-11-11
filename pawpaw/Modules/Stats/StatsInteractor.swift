//
//  StatsInteractor.swift
//  pawpaw
//

import Foundation

final class StatsInteractor: StatsInteractorInputProtocol {
    // TODO: To remove after swift bug is resolved.
    nonisolated deinit {}

    weak var presenter: StatsInteractorOutputProtocol?

    private let profile: CatProfile
    private let scoreStorage: ScoreStorage
    private let statsStorage: StatsStorage
    private let settings: SettingsStorage

    init(
        profile: CatProfile, scoreStorage: ScoreStorage, statsStorage: StatsStorage,
        settings: SettingsStorage
    ) {
        self.profile = profile
        self.scoreStorage = scoreStorage
        self.statsStorage = statsStorage
        self.settings = settings
    }

    func fetchTheme() {
        presenter?.didFetchTheme(settings.selectedTheme)
    }

    func fetchStats() {
        let scores = SessionMode.allCases
            .filter(\.hasHighScore)
            .map { (mode: $0, score: scoreStorage.highScore(for: $0)) }
        presenter?.didFetchStats(statsStorage.stats, bestScores: scores, profile: profile)
    }

    func resetStats() {
        statsStorage.reset()
        fetchStats()
    }
}
