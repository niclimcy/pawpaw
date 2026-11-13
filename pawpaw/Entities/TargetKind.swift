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
    case lizard

    /// The only theme this critter appears on; `nil` means every theme.
    var exclusiveTheme: PlayfieldTheme? {
        switch self {
        case .fish: return .pond
        case .lizard: return .grass
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
        case .lizard: return "lizards"
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
        case .lizard: return "critter_lizard"
        }
    }

    /// Drawn straight and rippled in the game, like a ribbon on a wand.
    var wavesAlongBody: Bool {
        self == .ribbon
    }

    /// The artwork on the playfield. Menus show `imageName`, which is curled for the ribbon.
    var fieldImageName: String {
        wavesAlongBody ? imageName + "_strip" : imageName
    }

    /// Artwork for a pose shown while it moves along the ground or through water:
    /// mid-stride, mid-stroke or mid-hop. `nil` when it has none.
    var movingImageName: String? {
        switch self {
        case .mouse, .bug, .cricket, .fish, .lizard: return imageName + "_move"
        case .butterfly, .feather, .laser, .ribbon, .bird: return nil
        }
    }

    /// Artwork for the opposite step to `movingImageName`. Drawn rather than mirrored,
    /// so markings and shading stay on the same side.
    var alternateMovingImageName: String? {
        switch self {
        case .mouse, .bug, .fish, .lizard: return imageName + "_move2"
        case .cricket, .butterfly, .feather, .laser, .ribbon, .bird: return nil
        }
    }

    /// Artwork with the wings spread, shown as it flies off the field.
    var flyingImageName: String? {
        switch self {
        case .bug, .bird: return imageName + "_fly"
        case .mouse, .cricket, .fish, .lizard, .butterfly, .feather, .laser, .ribbon: return nil
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
        case .lizard: return 15
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

    /// Whether it can roam the results card between rounds. Not the laser, which a cat can
    /// never truly catch.
    var canBeLure: Bool {
        self != .laser
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
        case .lizard: return 4.5...6.0
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
        case .lizard: return .scurry
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
        case .lizard: return 4
        }
    }
}
