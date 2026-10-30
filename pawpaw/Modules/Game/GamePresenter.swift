//
//  GamePresenter.swift
//  pawpaw
//

import Foundation

final class GamePresenter: GamePresenterProtocol, GameInteractorOutputProtocol {
    weak var view: GameViewProtocol?
    var interactor: GameInteractorInputProtocol?
    var router: GameRouterProtocol?

    // MARK: GamePresenterProtocol
    func viewDidBecomeReady() {
        startAfterCountdown()
    }

    func viewWillDisappear() {
        interactor?.stopGame()
    }

    func appWillResignActive() {
        interactor?.pauseGame()
    }

    func appDidBecomeActive() {
        interactor?.resumeGame()
    }

    func didTapTarget(id: UUID) {
        interactor?.catchTarget(id: id)
    }

    func didExpireTarget(id: UUID) {
        interactor?.expireTarget(id: id)
    }

    func didDiscardTarget(id: UUID) {
        interactor?.discardTarget(id: id)
    }

    func didMissTap() {
        interactor?.missTap()
    }

    func didTapPlayAgain() {
        view?.hideResult()
        view?.clearTargets()
        startAfterCountdown()
    }

    func didTapHome() {
        interactor?.recordExitHoldLearned()
        interactor?.stopGame()
        router?.navigateToHome(from: view)
    }

    private func startAfterCountdown() {
        let showsTip = interactor?.shouldShowExitTip ?? false
        view?.showGetReady(showsExitTip: showsTip) { [weak self] in
            self?.interactor?.startGame()
        }
    }

    // MARK: GameInteractorOutputProtocol
    func didUpdateScore(_ score: Int) {
        view?.showScore("Score: \(score)")
    }

    func didUpdateTimeRemaining(_ seconds: Int?) {
        view?.showTime(seconds.map { "⏱ \($0)" } ?? "⏱ ∞")
    }

    func didSpawnTarget(_ target: GameTarget) {
        view?.showTarget(target)
    }

    func didPlaceHidingSpots(_ points: [CGPoint]) {
        view?.showHidingSpots(points)
    }

    func didCatchTarget(id: UUID, points: Int) {
        view?.showCatch(targetID: id, points: points)
    }

    func didFinishGame(_ result: GameResult) {
        view?.clearTargets()
        let title = result.isNewHighScore ? "New Best! 🎉" : "Time's Up!"
        let critters = result.catches == 1 ? "critter" : "critters"
        let details = "You caught \(result.catches) \(critters)\nScore: \(result.score)\nBest: \(result.highScore)"
        view?.showResult(title: title, details: details)
    }

    func didPause() {
        view?.clearTargets()
        view?.showPaused()
    }

    func didResume() {
        view?.showResumed()
    }
}
