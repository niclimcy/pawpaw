//
//  HomeRouter.swift
//  pawpaw
//

import UIKit

final class HomeRouter: HomeRouterProtocol {
    static func createModule() -> UIViewController {
        let view = HomeViewController()
        let presenter = HomePresenter()
        let interactor = HomeInteractor(storage: UserDefaultsScoreStorage())
        let router = HomeRouter()

        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter

        let navigation = UINavigationController(rootViewController: view)
        navigation.setNavigationBarHidden(true, animated: false)
        return navigation
    }

    func navigateToGame(from view: HomeViewProtocol?, mode: SessionMode) {
        guard let viewController = view as? UIViewController else { return }
        let game = GameRouter.createModule(mode: mode)
        viewController.navigationController?.pushViewController(game, animated: true)
    }
}
