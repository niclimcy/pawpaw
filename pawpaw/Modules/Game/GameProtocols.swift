//
//  GameProtocols.swift
//  pawpaw
//

import UIKit

// MARK: - View
protocol GameViewProtocol: AnyObject {
    var presenter: GamePresenterProtocol? { get set }

    func showScore(_ text: String)
    func showTime(_ text: String)
    func showTarget(_ target: GameTarget)
    func showCatch(targetID: UUID, points: Int)
    func clearTargets()
    func showResult(title: String, details: String)
    func hideResult()
}

// MARK: - Presenter
protocol GamePresenterProtocol: AnyObject {
    var view: GameViewProtocol? { get set }
    var interactor: GameInteractorInputProtocol? { get set }
    var router: GameRouterProtocol? { get set }

    func viewDidLoad()
    func viewWillDisappear()
    func didTapTarget(id: UUID)
    func didExpireTarget(id: UUID)
    func didTapPlayAgain()
    func didTapHome()
}

// MARK: - Interactor
protocol GameInteractorInputProtocol: AnyObject {
    var presenter: GameInteractorOutputProtocol? { get set }

    func startGame()
    func stopGame()
    func catchTarget(id: UUID)
    func expireTarget(id: UUID)
}

protocol GameInteractorOutputProtocol: AnyObject {
    func didUpdateScore(_ score: Int)
    func didUpdateTimeRemaining(_ seconds: Int)
    func didSpawnTarget(_ target: GameTarget)
    func didCatchTarget(id: UUID, points: Int)
    func didFinishGame(_ result: GameResult)
}

// MARK: - Router
protocol GameRouterProtocol: AnyObject {
    static func createModule() -> UIViewController
    func navigateToHome(from view: GameViewProtocol?)
}
