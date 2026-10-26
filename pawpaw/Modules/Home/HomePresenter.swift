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
        interactor?.fetchHighScore()
    }

    func didTapPlay() {
        router?.navigateToGame(from: view)
    }

    func didFetchHighScore(_ score: Int) {
        view?.showHighScore(score)
    }
}
