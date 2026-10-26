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
    func viewDidLoad() {
        interactor?.startGame()
    }

    func viewWillDisappear() {
        interactor?.stopGame()
    }

    func didTapTarget(id: UUID) {
        interactor?.catchTarget(id: id)
    }

    func didExpireTarget(id: UUID) {
        interactor?.expireTarget(id: id)
    }

    func didTapPlayAgain() {
        view?.hideResult()
        view?.clearTargets()
        interactor?.startGame()
    }

    func didTapHome() {
        interactor?.stopGame()
        router?.navigateToHome(from: view)
    }

    // MARK: GameInteractorOutputProtocol
    func didUpdateScore(_ score: Int) {
        view?.showScore("Score: \(score)")
    }

    func didUpdateTimeRemaining(_ seconds: Int) {
        view?.showTime("⏱ \(seconds)")
    }

    func didSpawnTarget(_ target: GameTarget) {
        view?.showTarget(target)
    }

    func didCatchTarget(id: UUID, points: Int) {
        view?.showCatch(targetID: id, points: points)
    }

    func didFinishGame(_ result: GameResult) {
        view?.clearTargets()
        let title = result.isNewHighScore ? "New Best! 🎉" : "Time's Up!"
        let details = "You caught \(result.catches) critters\nScore: \(result.score)\nBest: \(result.highScore)"
        view?.showResult(title: title, details: details)
    }
}
