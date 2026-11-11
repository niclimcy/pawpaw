//
//  AdaptiveLayout.swift
//  pawpaw
//

import UIKit

enum AdaptiveLayout {
    /// Side by side rather than stacked: an iPad or iPhone Duo's inner display in landscape.
    /// The size class alone isn't enough: mid-fold it can still say regular while the bounds are
    /// already the outer display's (678 × 466pt in landscape), where side by side gets cut off.
    static func isWide(size: CGSize, horizontalSizeClass: UIUserInterfaceSizeClass) -> Bool {
        horizontalSizeClass == .regular && size.width > size.height
            && size.height >= minimumWideHeight
    }

    /// Below iPhone Duo's inner display in landscape (669pt) and above any phone's landscape height.
    static let minimumWideHeight: CGFloat = 600
}

extension UIViewController {
    var usesWideLayout: Bool {
        AdaptiveLayout.isWide(
            size: view.bounds.size, horizontalSizeClass: traitCollection.horizontalSizeClass)
    }

    /// A fold changes the size and the size class in separate steps, and the size class can
    /// arrive without a layout pass.
    func layOutAgainWhenSizeClassChanges() {
        guard #available(iOS 17.0, *) else { return }
        registerForTraitChanges([UITraitHorizontalSizeClass.self]) {
            (self: Self, _: UITraitCollection) in
            self.view.setNeedsLayout()
            // The change can land mid layout pass, which drops that request, so ask again after it.
            DispatchQueue.main.async { [weak self] in self?.view.setNeedsLayout() }
        }
    }
}

/// What a screen last laid out for; anything else means its fit has to be measured again.
/// Includes the safe area, which on iPhone Duo settles after the fold's size change.
struct LayoutEnvironment: Equatable {
    var size: CGSize
    var safeAreaInsets: UIEdgeInsets
    var horizontalSizeClass: UIUserInterfaceSizeClass

    init(_ controller: UIViewController) {
        size = controller.view.bounds.size
        safeAreaInsets = controller.view.safeAreaInsets
        horizontalSizeClass = controller.traitCollection.horizontalSizeClass
    }
}
