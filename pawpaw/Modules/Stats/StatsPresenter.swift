//
//  StatsPresenter.swift
//  pawpaw
//

import Foundation

final class StatsPresenter: StatsPresenterProtocol, StatsInteractorOutputProtocol {
    weak var view: StatsViewProtocol?
    var interactor: StatsInteractorInputProtocol?
    var router: StatsRouterProtocol?

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
    func didFetchStats(_ stats: PlayStats, bestScores: [(mode: SessionMode, score: Int)], profile: CatProfile) {
        let shortDay = DateFormatter()
        shortDay.setLocalizedDateFormatFromTemplate("EEE")
        let fullDay = DateFormatter()
        fullDay.setLocalizedDateFormatFromTemplate("EEEE")

        let favoriteKind = stats.favoriteKind
        view?.showStats(StatsViewModel(
            title: "\(profile.name)'s Stats",
            rounds: StatsViewModel.Metric(
                value: "\(stats.totalRounds)",
                caption: stats.totalRounds == 1 ? "Round" : "Rounds",
                accessibilityLabel: Self.count(stats.totalRounds, "round", "rounds")
            ),
            catches: StatsViewModel.Metric(
                value: "\(stats.totalCatches)",
                caption: stats.totalCatches == 1 ? "Catch" : "Catches",
                accessibilityLabel: Self.count(stats.totalCatches, "catch", "catches")
            ),
            favoriteImageName: favoriteKind?.imageName,
            favoriteAccessibilityLabel: favoriteKind.map { "Favorite catch: \($0.pluralName)" } ?? "No favorite catch yet",
            critters: TargetKind.allCases.map { kind in
                let catches = stats.catches(of: kind)
                return StatsViewModel.CritterRow(
                    imageName: kind.imageName,
                    catches: "\(catches)",
                    isEmpty: catches == 0,
                    accessibilityLabel: "\(kind.pluralName.capitalized): \(Self.count(catches, "catch", "catches"))"
                )
            },
            days: stats.recentRounds(days: historyDays).map { day in
                StatsViewModel.DayRow(
                    label: shortDay.string(from: day.date),
                    rounds: day.rounds,
                    accessibilityLabel: "\(fullDay.string(from: day.date)): \(Self.count(day.rounds, "round", "rounds"))"
                )
            },
            bestScores: bestScores.map {
                StatsViewModel.Metric(
                    value: "\($0.score)",
                    caption: $0.mode.title,
                    accessibilityLabel: "Best score, \($0.mode.title): \($0.score)"
                )
            }
        ))
    }

    private static func count(_ value: Int, _ singular: String, _ plural: String) -> String {
        switch value {
        case 0: return "no \(plural)"
        case 1: return "1 \(singular)"
        default: return "\(value) \(plural)"
        }
    }
}
