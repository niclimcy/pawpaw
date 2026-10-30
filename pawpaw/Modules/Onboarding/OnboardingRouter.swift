//
//  OnboardingRouter.swift
//  pawpaw
//

import UIKit

final class OnboardingRouter: OnboardingRouterProtocol {
    private let onFinish: () -> Void

    private init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    /// `onFinish` runs once the owner saves or skips the cat setup.
    static func createModule(onFinish: @escaping () -> Void) -> UIViewController {
        let view = OnboardingViewController()
        let presenter = OnboardingPresenter()
        let interactor = OnboardingInteractor(
            profileStorage: UserDefaultsProfileStorage(),
            settings: UserDefaultsSettingsStorage()
        )
        let router = OnboardingRouter(onFinish: onFinish)

        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router

        return view
    }

    func finish() {
        onFinish()
    }
}
