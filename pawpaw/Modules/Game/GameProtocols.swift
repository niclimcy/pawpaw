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
    /// Normalized (0...1) centers.
    func showHidingSpots(_ points: [CGPoint])
    func showCatch(targetID: UUID, points: Int)
    func clearTargets()
    func showResult(title: String, details: String)
    func hideResult()
    func showPaused()
    func showResumed()
    func showGetReady(showsExitTip: Bool, completion: @escaping () -> Void)
}

// MARK: - Presenter
protocol GamePresenterProtocol: AnyObject {
    var view: GameViewProtocol? { get set }
    var interactor: GameInteractorInputProtocol? { get set }
    var router: GameRouterProtocol? { get set }

    /// Called once the play area has its final size.
    func viewDidBecomeReady()
    func viewWillDisappear()
    func appWillResignActive()
    func appDidBecomeActive()
    func didTapTarget(id: UUID)
    func didExpireTarget(id: UUID)
    /// The view removed the critter itself (e.g. on resize); neither caught nor escaped.
    func didDiscardTarget(id: UUID)
    func didMissTap()
    func didTapPlayAgain()
    func didTapHome()
}

// MARK: - Interactor
protocol GameInteractorInputProtocol: AnyObject {
    var presenter: GameInteractorOutputProtocol? { get set }
    var shouldShowExitTip: Bool { get }

    func startGame()
    func stopGame()
    func pauseGame()
    func resumeGame()
    func catchTarget(id: UUID)
    func expireTarget(id: UUID)
    func discardTarget(id: UUID)
    func missTap()
    func recordExitHoldLearned()
}

protocol GameInteractorOutputProtocol: AnyObject {
    func didUpdateScore(_ score: Int)
    /// `nil` means the session has no timer.
    func didUpdateTimeRemaining(_ seconds: Int?)
    func didSpawnTarget(_ target: GameTarget)
    func didPlaceHidingSpots(_ points: [CGPoint])
    func didCatchTarget(id: UUID, points: Int)
    func didFinishGame(_ result: GameResult)
    /// On-screen critters no longer count and should be cleared.
    func didPause()
    func didResume()
}

// MARK: - Router
protocol GameRouterProtocol: AnyObject {
    static func createModule(mode: SessionMode) -> UIViewController
    func navigateToHome(from view: GameViewProtocol?)
}
