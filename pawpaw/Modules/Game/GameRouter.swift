//
//  GameRouter.swift
//  pawpaw
//

import UIKit

final class GameRouter: GameRouterProtocol {
    static func createModule(mode: SessionMode) -> UIViewController {
        let view = GameViewController()
        let presenter = GamePresenter()
        let profile = UserDefaultsProfileStorage().activeProfile
        let settings = UserDefaultsSettingsStorage()
        let theme = settings.selectedTheme
        let interactor = GameInteractor(
            storage: UserDefaultsScoreStorage(profileID: profile.id),
            statsStorage: UserDefaultsStatsStorage(profileID: profile.id),
            settings: settings,
            mode: mode,
            theme: theme,
            enabledKinds: profile.enabledKinds
        )
        let router = GameRouter()

        view.theme = theme
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
