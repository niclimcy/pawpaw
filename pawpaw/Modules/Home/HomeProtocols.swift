//
//  HomeProtocols.swift
//  pawpaw
//

import UIKit

// MARK: - View
protocol HomeViewProtocol: AnyObject {
    var presenter: HomePresenterProtocol? { get set }
    func showHighScore(_ score: Int)
}

// MARK: - Presenter
protocol HomePresenterProtocol: AnyObject {
    var view: HomeViewProtocol? { get set }
    var interactor: HomeInteractorInputProtocol? { get set }
    var router: HomeRouterProtocol? { get set }

    func viewWillAppear()
    func didTapPlay()
}

// MARK: - Interactor
protocol HomeInteractorInputProtocol: AnyObject {
    var presenter: HomeInteractorOutputProtocol? { get set }
    func fetchHighScore()
}

protocol HomeInteractorOutputProtocol: AnyObject {
    func didFetchHighScore(_ score: Int)
}

// MARK: - Router
protocol HomeRouterProtocol: AnyObject {
    static func createModule() -> UIViewController
    func navigateToGame(from view: HomeViewProtocol?)
}
