//
//  TargetKind.swift
//  pawpaw
//

import Foundation

enum TargetKind: String, CaseIterable {
    case mouse
    case bug
    case butterfly
    case cricket
    case feather
    case laser
    case fish
    case ribbon
    case bird

    /// The only theme this critter appears on; `nil` means every theme.
    var exclusiveTheme: PlayfieldTheme? {
        switch self {
        case .fish: return .pond
        default: return nil
        }
    }

    var pluralName: String {
        switch self {
        case .mouse: return "mice"
        case .bug: return "bugs"
        case .butterfly: return "butterflies"
        case .cricket: return "crickets"
        case .feather: return "feathers"
        case .laser: return "laser dots"
        case .fish: return "fish"
        case .ribbon: return "ribbons"
        case .bird: return "birds"
        }
    }

    var imageName: String {
        switch self {
        case .mouse: return "critter_mouse"
        case .bug: return "critter_bug"
        case .butterfly: return "critter_butterfly"
        case .cricket: return "critter_cricket"
        case .feather: return "critter_feather"
        case .laser: return "critter_laser"
        case .fish: return "critter_fish"
        case .ribbon: return "critter_ribbon"
        case .bird: return "critter_bird"
        }
    }

    var points: Int {
        switch self {
        case .mouse: return 10
        case .bug: return 5
        case .butterfly: return 20
        case .cricket: return 15
        case .feather: return 5
        case .laser: return 25
        case .fish: return 15
        case .ribbon: return 10
        case .bird: return 20
        }
    }

    func canAppear(on theme: PlayfieldTheme) -> Bool {
        exclusiveTheme.map { $0 == theme } ?? true
    }

    var turnsToFaceMovement: Bool {
        self != .laser
    }

    var glows: Bool {
        self == .laser
    }

    /// Seconds on screen.
    var lifetimeRange: ClosedRange<TimeInterval> {
        switch self {
        case .mouse: return 4.5...6.0
        case .bug: return 5.5...7.5
        case .butterfly: return 3.5...4.5
        case .cricket: return 4.5...6.0
        case .feather: return 6.0...8.0
        case .laser: return 4.0...5.5
        case .fish: return 5.0...7.0
        case .ribbon: return 6.0...8.0
        case .bird: return 5.0...7.0
        }
    }

    var movementStyle: MovementStyle {
        switch self {
        case .mouse: return .dart
        case .bug: return .wander
        case .butterfly: return .flutter
        case .cricket: return .hop
        case .feather: return .drift
        case .laser: return .zip
        case .fish: return .swim
        case .ribbon: return .slither
        case .bird: return .peck
        }
    }

    /// Relative spawn weight.
    var weight: Int {
        switch self {
        case .mouse: return 4
        case .bug: return 5
        case .butterfly: return 1
        case .cricket: return 3
        case .feather: return 2
        case .laser: return 2
        case .fish: return 4
        case .ribbon: return 3
        case .bird: return 2
        }
    }
}
