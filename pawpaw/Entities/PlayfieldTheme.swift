//
//  PlayfieldTheme.swift
//  pawpaw
//

import UIKit

enum PlayfieldTheme: String, CaseIterable {
    case wood
    case grass
    case pond
    case snow

    var title: String {
        switch self {
        case .wood: return "Crate"
        case .grass: return "Grass"
        case .pond: return "Pond"
        case .snow: return "Snow"
        }
    }

    /// Only fish hide under lily pads; land critters hide on every other theme.
    func allowsCover(for style: MovementStyle) -> Bool {
        guard style.coverChance > 0 else { return false }
        switch self {
        case .pond: return style == .swim
        case .wood, .grass, .snow: return style != .swim
        }
    }

    var baseColor: UIColor {
        switch self {
        case .wood: return Theme.background
        case .grass: return UIColor(red: 0.07, green: 0.16, blue: 0.08, alpha: 1)
        case .pond: return UIColor(red: 0.04, green: 0.12, blue: 0.20, alpha: 1)
        case .snow: return UIColor(red: 0.14, green: 0.18, blue: 0.26, alpha: 1)
        }
    }
}
