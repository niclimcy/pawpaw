//
//  StatsProtocols.swift
//  pawpaw
//

import UIKit

/// Everything the stats screen shows, already formatted as text.
struct StatsViewModel: Equatable {
    struct CritterRow: Equatable {
        let emoji: String
        let catches: String
    }

    struct DayRow: Equatable {
        let label: String
        let rounds: Int
    }

    let summary: String
    let favorite: String
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
    func didFetchStats(_ stats: PlayStats, bestScores: [(mode: SessionMode, score: Int)])
}

// MARK: - Router
protocol StatsRouterProtocol: AnyObject {
    static func createModule() -> UIViewController
    func navigateBack(from view: StatsViewProtocol?)
}
