//
//  TargetKind.swift
//  pawpaw
//

import Foundation

/// The kinds of prey that can scurry across the screen.
enum TargetKind: CaseIterable {
    case mouse
    case bug
    case butterfly

    var emoji: String {
        switch self {
        case .mouse: return "🐭"
        case .bug: return "🐞"
        case .butterfly: return "🦋"
        }
    }

    /// Name of the top-down SVG artwork in the asset catalog.
    var imageName: String {
        switch self {
        case .mouse: return "critter_mouse"
        case .bug: return "critter_bug"
        case .butterfly: return "critter_butterfly"
        }
    }

    var points: Int {
        switch self {
        case .mouse: return 10
        case .bug: return 5
        case .butterfly: return 20
        }
    }

    /// How long (in seconds) the target stays on screen. Faster prey is worth more.
    var lifetimeRange: ClosedRange<TimeInterval> {
        switch self {
        case .mouse: return 4.5...6.0
        case .bug: return 5.5...7.5
        case .butterfly: return 3.5...4.5
        }
    }

    /// Relative chance of spawning.
    var weight: Int {
        switch self {
        case .mouse: return 4
        case .bug: return 5
        case .butterfly: return 1
        }
    }
}
