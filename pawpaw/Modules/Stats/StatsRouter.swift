//
//  StatsRouter.swift
//  pawpaw
//

import UIKit

final class StatsRouter: StatsRouterProtocol {
    static func createModule() -> UIViewController {
        let view = StatsViewController()
        let presenter = StatsPresenter()
        let profile = UserDefaultsProfileStorage().activeProfile
        let interactor = StatsInteractor(
            profile: profile,
            scoreStorage: UserDefaultsScoreStorage(profileID: profile.id),
            statsStorage: UserDefaultsStatsStorage(profileID: profile.id)
        )
        let router = StatsRouter()

        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter

        return view
    }

    func navigateBack(from view: StatsViewProtocol?) {
        guard let viewController = view as? UIViewController else { return }
        viewController.navigationController?.popViewController(animated: true)
    }
}
