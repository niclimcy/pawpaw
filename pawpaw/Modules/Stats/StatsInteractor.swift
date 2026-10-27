//
//  StatsInteractor.swift
//  pawpaw
//

import Foundation

final class StatsInteractor: StatsInteractorInputProtocol {
    weak var presenter: StatsInteractorOutputProtocol?

    private let scoreStorage: ScoreStorage
    private let statsStorage: StatsStorage

    init(scoreStorage: ScoreStorage, statsStorage: StatsStorage) {
        self.scoreStorage = scoreStorage
        self.statsStorage = statsStorage
    }

    func fetchStats() {
        let scores = SessionMode.allCases
            .filter(\.hasHighScore)
            .map { (mode: $0, score: scoreStorage.highScore(for: $0)) }
        presenter?.didFetchStats(statsStorage.stats, bestScores: scores)
    }

    func resetStats() {
        statsStorage.reset()
        fetchStats()
    }
}
