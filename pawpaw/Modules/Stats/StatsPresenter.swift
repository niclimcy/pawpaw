//
//  StatsPresenter.swift
//  pawpaw
//

import Foundation

final class StatsPresenter: StatsPresenterProtocol, StatsInteractorOutputProtocol {
    weak var view: StatsViewProtocol?
    var interactor: StatsInteractorInputProtocol?
    var router: StatsRouterProtocol?

    /// How many days the play history chart covers.
    private let historyDays = 7

    // MARK: StatsPresenterProtocol
    func viewWillAppear() {
        interactor?.fetchStats()
    }

    func didTapBack() {
        router?.navigateBack(from: view)
    }

    func didConfirmReset() {
        interactor?.resetStats()
    }

    // MARK: StatsInteractorOutputProtocol
    func didFetchStats(_ stats: PlayStats, bestScores: [(mode: SessionMode, score: Int)]) {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE")

        let favorite = stats.favoriteKind.map { "Favorite catch: \($0.emoji)" } ?? "No favorite yet. Play a round!"
        view?.showStats(StatsViewModel(
            summary: "\(stats.totalRounds) rounds · \(stats.totalCatches) catches",
            favorite: favorite,
            critters: TargetKind.allCases.map {
                StatsViewModel.CritterRow(emoji: $0.emoji, catches: "\(stats.catches(of: $0))")
            },
            days: stats.recentRounds(days: historyDays).map {
                StatsViewModel.DayRow(label: formatter.string(from: $0.date), rounds: $0.rounds)
            },
            bestScores: bestScores.map { "\($0.mode.title): \($0.score)" }
        ))
    }
}
