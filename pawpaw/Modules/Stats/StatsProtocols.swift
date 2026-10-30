//
//  StatsProtocols.swift
//  pawpaw
//

import UIKit

struct StatsViewModel: Equatable {
    struct CritterRow: Equatable {
        let imageName: String
        let catches: String
        let isEmpty: Bool
        let accessibilityLabel: String
    }

    struct DayRow: Equatable {
        let label: String
        let rounds: Int
        let accessibilityLabel: String
    }

    /// A headline number with a short caption underneath.
    struct Metric: Equatable {
        let value: String
        let caption: String
        let accessibilityLabel: String
    }

    let title: String
    let rounds: Metric
    let catches: Metric
    let favoriteImageName: String?
    let favoriteAccessibilityLabel: String
    let critters: [CritterRow]
    let days: [DayRow]
    let bestScores: [Metric]
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
