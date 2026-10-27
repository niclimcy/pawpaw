//
//  StatsRouter.swift
//  pawpaw
//

import UIKit

final class StatsRouter: StatsRouterProtocol {
    static func createModule() -> UIViewController {
        let view = StatsViewController()
        let presenter = StatsPresenter()
        let profileID = UserDefaultsProfileStorage().activeProfile.id
        let interactor = StatsInteractor(
            scoreStorage: UserDefaultsScoreStorage(profileID: profileID),
            statsStorage: UserDefaultsStatsStorage(profileID: profileID)
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
