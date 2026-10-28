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
    /// The round is on hold (the app was interrupted): stop keeping the screen awake.
    func showPaused()
    /// Play has picked up again: keep the screen awake once more.
    func showResumed()
}

// MARK: - Presenter
protocol GamePresenterProtocol: AnyObject {
    var view: GameViewProtocol? { get set }
    var interactor: GameInteractorInputProtocol? { get set }
    var router: GameRouterProtocol? { get set }

    /// The play area has its final size, so the round can begin.
    func viewDidBecomeReady()
    func viewWillDisappear()
    /// The app went into the background or was interrupted (a call, Control Center).
    func appWillResignActive()
    /// The app is in front and active again.
    func appDidBecomeActive()
    func didTapTarget(id: UUID)
    func didExpireTarget(id: UUID)
    /// The view removed a critter itself (the field was resized), so it is neither caught nor escaped.
    func didDiscardTarget(id: UUID)
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
    /// Freezes the round's clock and spawning and saves the catches so far, in case the app is closed.
    func pauseGame()
    func resumeGame()
    func catchTarget(id: UUID)
    func expireTarget(id: UUID)
    /// Frees the critter's slot without counting it as caught or escaped.
    func discardTarget(id: UUID)
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
    /// The round paused; critters on screen no longer count and should be cleared.
    func didPause()
    func didResume()
}

// MARK: - Router
protocol GameRouterProtocol: AnyObject {
    static func createModule(mode: SessionMode) -> UIViewController
    func navigateToHome(from view: GameViewProtocol?)
}
