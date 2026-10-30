//
//  CritterVariant.swift
//  pawpaw
//

import CoreGraphics

/// A fresh look for a critter the cat has got used to.
/// Cats see blue, yellow and brightness well but reds look dull, so the looks change those.
enum CritterVariant: Int, CaseIterable {
    case standard
    case pale
    case dusk
    case large

    /// A colour washed over the artwork; `amount` is 0...1.
    struct Tint: Equatable {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let amount: CGFloat
    }

    /// The look after `index` refreshes, cycling through every variant.
    static func cycled(_ index: Int) -> CritterVariant {
        allCases[index % allCases.count]
    }

    /// Multiplies the critter's size.
    var scale: CGFloat {
        switch self {
        case .standard, .dusk: return 1
        case .pale: return 0.88
        case .large: return 1.2
        }
    }

    var tint: Tint? {
        switch self {
        case .standard: return nil
        // Brighter and paler.
        case .pale: return Tint(red: 1, green: 1, blue: 1, amount: 0.4)
        // Shifted towards blue.
        case .dusk: return Tint(red: 0.3, green: 0.5, blue: 1, amount: 0.45)
        // Shifted towards yellow.
        case .large: return Tint(red: 1, green: 0.85, blue: 0.25, amount: 0.3)
        }
    }
}
