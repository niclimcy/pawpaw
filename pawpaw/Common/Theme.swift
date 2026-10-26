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

    static func roundedFont(size: CGFloat, weight: UIFont.Weight = .heavy) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}
