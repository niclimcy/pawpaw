//
//  UIView+Shake.swift
//  pawpaw
//

import UIKit

extension UIView {
    /// A short side-to-side "no", skipped under Reduce Motion; pair it with a visible or spoken hint.
    func shakeHorizontally() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.values = [0, -8, 8, -5, 5, 0]
        shake.duration = 0.3
        layer.add(shake, forKey: "shake")
    }
}
