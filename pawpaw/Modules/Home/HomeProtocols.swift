//
//  HomeProtocols.swift
//  pawpaw
//

import UIKit

// MARK: - View
protocol HomeViewProtocol: AnyObject {
    var presenter: HomePresenterProtocol? { get set }
    func showMode(_ mode: SessionMode)
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
    func didTapPlay()
}

// MARK: - Interactor
protocol HomeInteractorInputProtocol: AnyObject {
    var presenter: HomeInteractorOutputProtocol? { get set }
    var selectedMode: SessionMode { get }
    func fetchState()
    func selectMode(_ mode: SessionMode)
}

protocol HomeInteractorOutputProtocol: AnyObject {
    func didFetchState(mode: SessionMode, highScore: Int?)
}

// MARK: - Router
protocol HomeRouterProtocol: AnyObject {
    static func createModule() -> UIViewController
    func navigateToGame(from view: HomeViewProtocol?, mode: SessionMode)
}
