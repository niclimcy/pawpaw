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
    /// Normalized (0...1) centers of the spots critters can hide under.
    func showHidingSpots(_ points: [CGPoint])
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
    /// A paw landed on empty space.
    func didMissTap()
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
    func missTap()
}

protocol GameInteractorOutputProtocol: AnyObject {
    func didUpdateScore(_ score: Int)
    /// `nil` means the session has no timer (relaxed mode).
    func didUpdateTimeRemaining(_ seconds: Int?)
    func didSpawnTarget(_ target: GameTarget)
    func didPlaceHidingSpots(_ points: [CGPoint])
    func didCatchTarget(id: UUID, points: Int)
    func didFinishGame(_ result: GameResult)
}

// MARK: - Router
protocol GameRouterProtocol: AnyObject {
    static func createModule(mode: SessionMode) -> UIViewController
    func navigateToHome(from view: GameViewProtocol?)
}
