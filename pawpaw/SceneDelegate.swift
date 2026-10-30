//
//  SceneDelegate.swift
//  pawpaw
//
//  Created by Nicholas Lim on 26/10/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        let settings = UserDefaultsSettingsStorage()
        window?.rootViewController = settings.hasCompletedOnboarding
            ? HomeRouter.createModule()
            : OnboardingRouter.createModule(onFinish: { [weak self] in self?.showHome() })
        window?.makeKeyAndVisible()
    }

    private func showHome() {
        guard let window else { return }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = HomeRouter.createModule()
        }
    }
}

