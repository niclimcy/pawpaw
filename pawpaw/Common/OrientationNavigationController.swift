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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        matchSafeAreaToStatusBar()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // The status bar shows or hides as the rotation finishes, which doesn't always lay out again.
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.matchSafeAreaToStatusBar()
        }
    }

    /// iPhones without a notch hide the status bar in landscape, but after the game rotates the screen the
    /// window's top safe area keeps the old orientation's value: 20pt with no status bar in landscape,
    /// 0pt under the status bar back in portrait. On those phones the top safe area is just the status bar,
    /// so this corrects it to the status bar's real height. Zero once UIKit reports the right value.
    private func matchSafeAreaToStatusBar() {
        guard let window = view.window else { return }
        // Notched phones and newer iPads always have a bottom inset; their safe area isn't the status bar's.
        let reported = window.safeAreaInsets
        guard reported.bottom == 0, let statusBar = window.windowScene?.statusBarManager else { return }
        let statusBarHeight = statusBar.isStatusBarHidden ? 0 : statusBar.statusBarFrame.height
        let correction = statusBarHeight - reported.top
        guard additionalSafeAreaInsets.top != correction else { return }
        additionalSafeAreaInsets.top = correction
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        topViewController?.preferredInterfaceOrientationForPresentation
            ?? super.preferredInterfaceOrientationForPresentation
    }
}
