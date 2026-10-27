//
//  ProfilesRouter.swift
//  pawpaw
//

import UIKit

final class ProfilesRouter: ProfilesRouterProtocol {
    static func createModule() -> UIViewController {
        let view = ProfilesViewController()
        let presenter = ProfilesPresenter()
        let interactor = ProfilesInteractor(
            profileStorage: UserDefaultsProfileStorage(),
            makeStatsStorage: { UserDefaultsStatsStorage(profileID: $0) }
        )
        let router = ProfilesRouter()

        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter

        return view
    }

    func navigateBack(from view: ProfilesViewProtocol?) {
        guard let viewController = view as? UIViewController else { return }
        viewController.navigationController?.popViewController(animated: true)
    }
}
