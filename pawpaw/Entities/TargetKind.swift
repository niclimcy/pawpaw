//
//  TargetKind.swift
//  pawpaw
//

import Foundation

/// The kinds of prey that can scurry across the screen.
enum TargetKind: String, CaseIterable {
    case mouse
    case bug
    case butterfly
    case cricket
    case feather

    var emoji: String {
        switch self {
        case .mouse: return "🐭"
        case .bug: return "🐞"
        case .butterfly: return "🦋"
        case .cricket: return "🦗"
        case .feather: return "🪶"
        }
    }

    /// Name of the top-down SVG artwork in the asset catalog.
    var imageName: String {
        switch self {
        case .mouse: return "critter_mouse"
        case .bug: return "critter_bug"
        case .butterfly: return "critter_butterfly"
        case .cricket: return "critter_cricket"
        case .feather: return "critter_feather"
        }
    }

    var points: Int {
        switch self {
        case .mouse: return 10
        case .bug: return 5
        case .butterfly: return 20
        case .cricket: return 15
        case .feather: return 5
        }
    }

    /// How long (in seconds) the target stays on screen. Faster prey is worth more.
    var lifetimeRange: ClosedRange<TimeInterval> {
        switch self {
        case .mouse: return 4.5...6.0
        case .bug: return 5.5...7.5
        case .butterfly: return 3.5...4.5
        case .cricket: return 4.5...6.0
        case .feather: return 6.0...8.0
        }
    }

    var movementStyle: MovementStyle {
        switch self {
        case .mouse: return .dart
        case .bug: return .wander
        case .butterfly: return .flutter
        case .cricket: return .hop
        case .feather: return .drift
        }
    }

    /// Relative chance of spawning.
    var weight: Int {
        switch self {
        case .mouse: return 4
        case .bug: return 5
        case .butterfly: return 1
        case .cricket: return 3
        case .feather: return 2
        }
    }
}
