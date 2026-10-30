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
        window?.rootViewController = HomeRouter.createModule()
        window?.makeKeyAndVisible()
    }
}

