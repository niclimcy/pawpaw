//
//  HomeProtocols.swift
//  pawpaw
//

import UIKit

// MARK: - View
protocol HomeViewProtocol: AnyObject {
    var presenter: HomePresenterProtocol? { get set }
    func showMode(_ mode: SessionMode)
    func showTheme(_ theme: PlayfieldTheme)
    /// `nil` hides the best score (relaxed mode has none).
    func showHighScore(_ score: Int?)
}

// MARK: - Presenter
protocol HomePresenterProtocol: AnyObject {
    var view: HomeViewProtocol? { get set }
    var interactor: HomeInteractorInputProtocol? { get set }
    var router: HomeRouterProtocol? { get set }

    func viewWillAppear()
    func didSelectMode(_ mode: SessionMode)
    func didSelectTheme(_ theme: PlayfieldTheme)
    func didTapPlay()
    func didRequestStats()
}

// MARK: - Interactor
protocol HomeInteractorInputProtocol: AnyObject {
    var presenter: HomeInteractorOutputProtocol? { get set }
    var selectedMode: SessionMode { get }
    func fetchState()
    func selectMode(_ mode: SessionMode)
    func selectTheme(_ theme: PlayfieldTheme)
}

protocol HomeInteractorOutputProtocol: AnyObject {
    func didFetchState(mode: SessionMode, theme: PlayfieldTheme, highScore: Int?)
}

// MARK: - Router
protocol HomeRouterProtocol: AnyObject {
    static func createModule() -> UIViewController
    func navigateToGame(from view: HomeViewProtocol?, mode: SessionMode)
    func navigateToStats(from view: HomeViewProtocol?)
}
