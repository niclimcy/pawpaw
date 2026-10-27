//
//  GameRouter.swift
//  pawpaw
//

import UIKit

final class GameRouter: GameRouterProtocol {
    static func createModule(mode: SessionMode) -> UIViewController {
        let view = GameViewController()
        let presenter = GamePresenter()
        let storage = UserDefaultsScoreStorage()
        let interactor = GameInteractor(storage: storage, mode: mode)
        let router = GameRouter()

        view.theme = storage.selectedTheme
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter

        return view
    }

    func navigateToHome(from view: GameViewProtocol?) {
        guard let viewController = view as? UIViewController else { return }
        viewController.navigationController?.popViewController(animated: true)
    }
}
