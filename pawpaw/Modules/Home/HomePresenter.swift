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

    func didRequestStats() {
        router?.navigateToStats(from: view)
    }

    func didTapProfile() {
        router?.navigateToProfiles(from: view)
    }

    func didSelectTheme(_ theme: PlayfieldTheme) {
        interactor?.selectTheme(theme)
    }

    func didFetchState(
        mode: SessionMode,
        theme: PlayfieldTheme,
        highScore: Int?,
        profile: CatProfile,
        favorite: TargetKind?
    ) {
        view?.showMode(mode)
        view?.showTheme(theme)
        view?.showHighScore(highScore)
        view?.showProfile(
            name: profile.name,
            face: profile.face,
            favorite: favorite.map { "\(profile.name) loves \($0.pluralName)" }
        )
    }
}
