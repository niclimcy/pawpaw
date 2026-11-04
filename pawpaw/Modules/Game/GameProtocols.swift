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
    /// Stops critters and effects where they are, ignoring touches, until `resumeTargets()`.
    func freezeTargets()
    func resumeTargets()
    /// `symbol` is an SF Symbol name shown after the title.
    func showResult(title: String, symbol: String?, details: String)
    func hideResult()
    func showPaused()
    func showResumed()
    func showGetReady(showsExitTip: Bool, completion: @escaping () -> Void)

    // Lure: one critter that roams under the results card between timed rounds.
    /// After a short wait, so a late pounce doesn't count, reports the card as cover via `didBecomeReadyForLure`.
    func showLureWhenReady()
    /// One loop of the lure; a leaving lure runs off and is removed.
    func showLure(_ target: GameTarget, isLeaving: Bool)
    func showLureCaught()
    /// The cat's last catch for now; no new round starts.
    func showFinalCatch(_ message: String, symbol: String?)
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
    /// `lastTouch` is normalized, roughly where the cat is.
    func didBecomeReadyForLure(cover: LureCover, lastTouch: CGPoint?)
    /// Normalized position where the lure's loop ended.
    func didFinishLureLoop(at point: CGPoint)
    /// Nobody has played for a while; normalized position of the lure.
    func didIdleWithLure(at point: CGPoint)
    func didTapLure()
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

    // Lure, between timed rounds. Never scored or counted in stats.
    /// Sends in a lure from the side away from `touch`, or brings the current one back after a relayout.
    func startLure(cover: LureCover, awayFrom touch: CGPoint?)
    func continueLure(from point: CGPoint)
    func sendLureAway(from point: CGPoint)
    func catchLure()
    /// An owner started a round, so automatic rounds count from zero again.
    func resetAutoRounds()
}

protocol GameInteractorOutputProtocol: AnyObject {
    func didUpdateScore(_ score: Int)
    /// `nil` means the session has no timer.
    func didUpdateTimeRemaining(_ seconds: Int?)
    func didSpawnTarget(_ target: GameTarget)
    func didPlaceHidingSpots(_ points: [CGPoint])
    func didCatchTarget(id: UUID, points: Int)
    func didFinishGame(_ result: GameResult)
    /// On-screen critters still count and should freeze where they are.
    func didPause()
    func didResume()
    func didMoveLure(_ target: GameTarget, isLeaving: Bool)
    func didCatchLure(startsNextRound: Bool)
}

// MARK: - Router
protocol GameRouterProtocol: AnyObject {
    static func createModule(mode: SessionMode) -> UIViewController
    func navigateToHome(from view: GameViewProtocol?)
}
