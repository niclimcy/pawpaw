//
//  StatsInteractor.swift
//  pawpaw
//

import Foundation

final class StatsInteractor: StatsInteractorInputProtocol {
    weak var presenter: StatsInteractorOutputProtocol?

    private let profile: CatProfile
    private let scoreStorage: ScoreStorage
    private let statsStorage: StatsStorage

    init(profile: CatProfile, scoreStorage: ScoreStorage, statsStorage: StatsStorage) {
        self.profile = profile
        self.scoreStorage = scoreStorage
        self.statsStorage = statsStorage
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
