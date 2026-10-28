//
//  StatsProtocols.swift
//  pawpaw
//

import UIKit

/// Everything the stats screen shows, already formatted as text.
struct StatsViewModel: Equatable {
    struct CritterRow: Equatable {
        /// Name of the critter's SVG in the asset catalog.
        let imageName: String
        let catches: String
        /// What VoiceOver reads for the column, such as "Mice: 3 catches".
        let accessibilityLabel: String
    }

    struct DayRow: Equatable {
        let label: String
        let rounds: Int
        /// What VoiceOver reads for the bar, such as "Monday: 2 rounds".
        let accessibilityLabel: String
    }

    let title: String
    let summary: String
    let favorite: String
    /// The favorite critter's SVG name, or `nil` when nothing has been caught yet.
    let favoriteImageName: String?
    /// The favorite line with the critter named, since VoiceOver can't read the picture.
    let favoriteAccessibilityLabel: String
    let critters: [CritterRow]
    let days: [DayRow]
    let bestScores: [String]
}

// MARK: - View
protocol StatsViewProtocol: AnyObject {
    var presenter: StatsPresenterProtocol? { get set }
    func showStats(_ viewModel: StatsViewModel)
}

// MARK: - Presenter
protocol StatsPresenterProtocol: AnyObject {
    var view: StatsViewProtocol? { get set }
    var interactor: StatsInteractorInputProtocol? { get set }
    var router: StatsRouterProtocol? { get set }

    func viewWillAppear()
    func didTapBack()
    func didConfirmReset()
}

// MARK: - Interactor
protocol StatsInteractorInputProtocol: AnyObject {
    var presenter: StatsInteractorOutputProtocol? { get set }
    func fetchStats()
    func resetStats()
}

protocol StatsInteractorOutputProtocol: AnyObject {
    func didFetchStats(_ stats: PlayStats, bestScores: [(mode: SessionMode, score: Int)], profile: CatProfile)
}

// MARK: - Router
protocol StatsRouterProtocol: AnyObject {
    static func createModule() -> UIViewController
    func navigateBack(from view: StatsViewProtocol?)
}
