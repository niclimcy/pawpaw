//
//  HomePresenter.swift
//  pawpaw
//

import Foundation

final class HomePresenter: HomePresenterProtocol, HomeInteractorOutputProtocol {
    weak var view: HomeViewProtocol?
    var interactor: HomeInteractorInputProtocol?
    var router: HomeRouterProtocol?

    func viewWillAppear() {
        interactor?.fetchState()
    }

    func didSelectMode(_ mode: SessionMode) {
        interactor?.selectMode(mode)
    }

    func didTapPlay() {
        guard let mode = interactor?.selectedMode else { return }
        router?.navigateToGame(from: view, mode: mode)
    }

    func didFetchState(mode: SessionMode, highScore: Int?) {
        view?.showMode(mode)
        view?.showHighScore(highScore)
    }
}
