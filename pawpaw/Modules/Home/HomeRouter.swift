//
//  HomeRouter.swift
//  pawpaw
//

import UIKit

final class HomeRouter: HomeRouterProtocol {
    static func createModule() -> UIViewController {
        let view = HomeViewController()
        let presenter = HomePresenter()
        let interactor = HomeInteractor(
            profileStorage: UserDefaultsProfileStorage(),
            settings: UserDefaultsSettingsStorage(),
            makeScoreStorage: { UserDefaultsScoreStorage(profileID: $0) },
            makeStatsStorage: { UserDefaultsStatsStorage(profileID: $0) }
        )
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

    func navigateToStats(from view: HomeViewProtocol?) {
        guard let viewController = view as? UIViewController else { return }
        viewController.navigationController?.pushViewController(StatsRouter.createModule(), animated: true)
    }

    func navigateToProfiles(from view: HomeViewProtocol?) {
        guard let viewController = view as? UIViewController else { return }
        viewController.navigationController?.pushViewController(ProfilesRouter.createModule(), animated: true)
    }
}
