//
//  OrientationNavigationController.swift
//  pawpaw
//

import UIKit

extension UIInterfaceOrientationMask {
    /// iPad and iPhone Duo's inner display have room in either orientation, so they follow the device.
    /// Other iPhones keep menus portrait and turn the game to landscape.
    static var followsDevice: Bool {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        return UIDevice.current.userInterfaceIdiom == .pad
            || scene.map { hasRoomBothWays($0.traitCollection) } == true
    }

    /// Regular width and height: a full-screen iPad or iPhone Duo's inner display.
    static func hasRoomBothWays(_ traits: UITraitCollection) -> Bool {
        traits.horizontalSizeClass == .regular && traits.verticalSizeClass == .regular
    }

    /// Portrait-only where the game turns to landscape, so leaving it always turns back.
    static var menus: UIInterfaceOrientationMask {
        followsDevice ? .all : .portrait
    }
}

/// Uses the top screen's orientations, which a plain navigation controller ignores.
final class OrientationNavigationController: UINavigationController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let top = topViewController?.supportedInterfaceOrientations ?? .menus
        // Only the game excludes portrait; every other screen is a menu.
        return top.contains(.portrait) ? top.intersection(.menus) : top
    }

    /// Last `followsDevice` the orientations were checked at; folding iPhone Duo changes it.
    private var followedDevice: Bool?

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        matchSafeAreaToStatusBar()
        updateOrientationsAfterResize()
    }

    private func updateOrientationsAfterResize() {
        let follows = UIInterfaceOrientationMask.followsDevice
        guard follows != followedDevice else { return }
        let isFirstCheck = followedDevice == nil
        followedDevice = follows
        guard !isFirstCheck else { return }
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
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
        guard reported.bottom == 0, let statusBar = window.windowScene?.statusBarManager else {
            return
        }
        let correction = Self.topInsetCorrection(
            reportedTop: reported.top,
            statusBarFrame: statusBar.isStatusBarHidden ? .zero : statusBar.statusBarFrame
        )
        guard additionalSafeAreaInsets.top != correction else { return }
        additionalSafeAreaInsets.top = correction
    }

    /// On iPhone Duo the status bar can run down a side, where its height isn't the top inset.
    static func topInsetCorrection(reportedTop: CGFloat, statusBarFrame: CGRect) -> CGFloat {
        let alongTop = statusBarFrame.minY == 0 && statusBarFrame.width >= statusBarFrame.height
        return alongTop ? statusBarFrame.height - reportedTop : 0
    }

    override func viewWillTransition(
        to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        // The status bar shows or hides as the rotation finishes, which doesn't always lay out again.
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.matchSafeAreaToStatusBar()
        }
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        topViewController?.preferredInterfaceOrientationForPresentation
            ?? super.preferredInterfaceOrientationForPresentation
    }
}
