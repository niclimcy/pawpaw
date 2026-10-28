//
//  PlayfieldTheme.swift
//  pawpaw
//

import UIKit

/// The surface the critters run across. Every theme is dark so the critters and effects stand out.
enum PlayfieldTheme: String, CaseIterable {
    case wood
    case grass
    case pond
    case snow

    /// Short label for the theme picker.
    var title: String {
        switch self {
        case .wood: return "Crate"
        case .grass: return "Grass"
        case .pond: return "Pond"
        case .snow: return "Snow"
        }
    }

    /// Whether critters that move with `style` may hide under this background's hiding spots.
    /// Only fish slip under lily pads; land critters would have to walk on water to reach them.
    func allowsCover(for style: MovementStyle) -> Bool {
        switch self {
        case .pond: return style == .swim
        case .wood, .grass, .snow: return style != .swim
        }
    }

    /// Fill colour under whatever the theme draws on top.
    var baseColor: UIColor {
        switch self {
        case .wood: return Theme.background
        case .grass: return UIColor(red: 0.07, green: 0.16, blue: 0.08, alpha: 1)
        case .pond: return UIColor(red: 0.04, green: 0.12, blue: 0.20, alpha: 1)
        case .snow: return UIColor(red: 0.14, green: 0.18, blue: 0.26, alpha: 1)
        }
    }
}
