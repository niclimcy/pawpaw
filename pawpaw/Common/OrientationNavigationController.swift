//
//  OrientationNavigationController.swift
//  pawpaw
//

import UIKit

extension UIInterfaceOrientationMask {
    /// Menus are portrait-only on iPhone, so leaving the landscape game always turns back.
    static var menus: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
    }
}

/// Uses the top screen's orientations, which a plain navigation controller ignores.
final class OrientationNavigationController: UINavigationController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let top = topViewController?.supportedInterfaceOrientations ?? .menus
        // Only the game excludes portrait; every other screen is a menu.
        return top.contains(.portrait) ? top.intersection(.menus) : top
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        topViewController?.preferredInterfaceOrientationForPresentation
            ?? super.preferredInterfaceOrientationForPresentation
    }
}
