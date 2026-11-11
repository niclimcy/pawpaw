//
//  StatsPresenter.swift
//  pawpaw
//

import Foundation

/// A countable word, so "1 round", "2 rounds" and "no rounds" stay consistent.
private struct Noun {
    let singular: String
    let plural: String

    static let round = Noun(singular: "round", plural: "rounds")
    static let `catch` = Noun(singular: "catch", plural: "catches")

    func title(for count: Int) -> String {
        (count == 1 ? singular : plural).capitalized
    }

    func phrase(for count: Int) -> String {
        switch count {
        case 0: return "no \(plural)"
        case 1: return "1 \(singular)"
        default: return "\(count) \(plural)"
        }
    }
}

final class StatsPresenter: StatsPresenterProtocol, StatsInteractorOutputProtocol {
    // TODO: To remove after swift bug is resolved.
    nonisolated deinit {}

    weak var view: StatsViewProtocol?
    var interactor: StatsInteractorInputProtocol?
    var router: StatsRouterProtocol?

    private static let historyDays = 7

    // MARK: StatsPresenterProtocol
    func viewDidLoad() {
        interactor?.fetchTheme()
    }

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
    func didFetchTheme(_ theme: PlayfieldTheme) {
        view?.showTheme(theme)
    }

    func didFetchStats(
        _ stats: PlayStats, bestScores: [(mode: SessionMode, score: Int)], profile: CatProfile
    ) {
        let shortDay = DateFormatter()
        shortDay.setLocalizedDateFormatFromTemplate("EEE")
        let fullDay = DateFormatter()
        fullDay.setLocalizedDateFormatFromTemplate("EEEE")

        let favoriteKind = stats.favoriteKind
        view?.showStats(
            StatsViewModel(
                title: "\(profile.name)'s Stats",
                rounds: StatsViewModel.Metric(
                    value: "\(stats.totalRounds)",
                    caption: Noun.round.title(for: stats.totalRounds),
                    accessibilityLabel: Noun.round.phrase(for: stats.totalRounds)
                ),
                catches: StatsViewModel.Metric(
                    value: "\(stats.totalCatches)",
                    caption: Noun.catch.title(for: stats.totalCatches),
                    accessibilityLabel: Noun.catch.phrase(for: stats.totalCatches)
                ),
                favoriteImageName: favoriteKind?.imageName,
                favoriteAccessibilityLabel: favoriteKind.map { "Favorite catch: \($0.pluralName)" }
                    ?? "No favorite catch yet",
                critters: TargetKind.allCases.map { kind in
                    let catches = stats.catches(of: kind)
                    return StatsViewModel.CritterRow(
                        imageName: kind.imageName,
                        catches: "\(catches)",
                        isEmpty: catches == 0,
                        accessibilityLabel:
                            "\(kind.pluralName.capitalized): \(Noun.catch.phrase(for: catches))"
                    )
                },
                daysHeading: "Rounds in the last \(Self.historyDays) days",
                days: stats.recentRounds(days: Self.historyDays).map { day in
                    StatsViewModel.DayRow(
                        label: shortDay.string(from: day.date),
                        rounds: day.rounds,
                        accessibilityLabel:
                            "\(fullDay.string(from: day.date)): \(Noun.round.phrase(for: day.rounds))"
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
}
