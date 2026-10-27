//
//  Theme.swift
//  pawpaw
//

import UIKit

enum Theme {
    /// Base colour of the dark wooden crate.
    static let background = UIColor(red: 0.16, green: 0.10, blue: 0.06, alpha: 1.0)
    /// Slightly lighter wood used for cards/panels.
    static let panel = UIColor(red: 0.27, green: 0.17, blue: 0.10, alpha: 1.0)
    static let accent = UIColor(red: 1.0, green: 0.62, blue: 0.20, alpha: 1.0)
    static let gold = UIColor(red: 1.0, green: 0.84, blue: 0.30, alpha: 1.0)
    static let text = UIColor(red: 1.0, green: 0.94, blue: 0.80, alpha: 1.0)

    /// Apple's minimum comfortable touch target.
    static let minimumTapSize: CGFloat = 44

    /// Menus are laid out for a phone and scaled up on iPad.
    static var uiScale: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 1.4 : 1
    }

    static func scaled(_ value: CGFloat) -> CGFloat {
        value * uiScale
    }

    /// Dark-wood styling shared by the Home pickers.
    static func styleSegmented(_ control: UISegmentedControl, fontSize: CGFloat) {
        control.selectedSegmentTintColor = accent
        control.backgroundColor = panel
        let font = roundedFont(size: scaled(fontSize), weight: .bold)
        control.setTitleTextAttributes([.foregroundColor: text, .font: font], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: font], for: .selected)
        control.heightAnchor.constraint(greaterThanOrEqualToConstant: max(minimumTapSize, scaled(36))).isActive = true
    }

    static func roundedFont(size: CGFloat, weight: UIFont.Weight = .heavy) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}
