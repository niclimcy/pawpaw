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
        interactor?.resetAutoRounds()
        view?.hideResult()
        view?.clearTargets()
        startAfterCountdown()
    }

    func didTapHome() {
        interactor?.recordExitHoldLearned()
        interactor?.stopGame()
        router?.navigateToHome(from: view)
    }

    func didBecomeReadyForLure(cover: LureCover, lastTouch: CGPoint?) {
        interactor?.startLure(cover: cover, awayFrom: lastTouch)
    }

    func didFinishLureLoop(at point: CGPoint) {
        interactor?.continueLure(from: point)
    }

    func didIdleWithLure(at point: CGPoint) {
        interactor?.sendLureAway(from: point)
    }

    func didTapLure() {
        interactor?.catchLure()
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
        view?.showTime(seconds.map { "\($0)" } ?? "∞")
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
        let title = result.isNewHighScore ? "New Best!" : "Time's Up!"
        let symbol = result.isNewHighScore ? "sparkles" : nil
        let critters = result.catches == 1 ? "critter" : "critters"
        let details = "You caught \(result.catches) \(critters)\nScore: \(result.score)\nBest: \(result.highScore)"
        view?.showResult(title: title, symbol: symbol, details: details)
        view?.showLureWhenReady()
    }

    func didMoveLure(_ target: GameTarget, isLeaving: Bool) {
        view?.showLure(target, isLeaving: isLeaving)
    }

    func didCatchLure(startsNextRound: Bool) {
        view?.showLureCaught()
        guard startsNextRound else {
            view?.showFinalCatch("Great hunt!", symbol: "pawprint.fill")
            return
        }
        view?.hideResult()
        view?.clearTargets()
        startAfterCountdown()
    }

    func didPause() {
        view?.freezeTargets()
        view?.showPaused()
    }

    func didResume() {
        view?.resumeTargets()
        view?.showResumed()
    }
}
