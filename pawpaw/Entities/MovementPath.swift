//
//  MovementPath.swift
//  pawpaw
//

import CoreGraphics
import Foundation

struct PathLeg: Equatable {
    /// Normalized (0...1).
    let destination: CGPoint
    let travel: TimeInterval
    /// Freeze at the destination before the next leg.
    let pause: TimeInterval
    /// Runs off the nearest edge during the pause, then returns.
    let hides: Bool
    /// Final leg off the edge of the field.
    var exits: Bool = false
    /// Destination is a hiding spot; the critter peeks out during the pause.
    var underCover: Bool = false
}

enum MovementStyle {
    case dart
    case wander
    case flutter
    case hop
    case drift
    case zip
    case swim

    /// Fades in and out in place instead of entering and leaving via an edge.
    var surfaces: Bool {
        self == .swim
    }

    var legCount: ClosedRange<Int> {
        switch self {
        case .swim: return 5...7
        case .dart: return 3...4
        case .wander: return 4...5
        case .flutter: return 6...8
        case .hop: return 6...8
        case .drift: return 4...5
        case .zip: return 5...7
        }
    }

    var hideChance: Double {
        switch self {
        case .swim: return 0
        case .dart: return 0.6
        case .wander: return 0.3
        case .flutter: return 0
        case .hop: return 0.2
        case .drift: return 0
        case .zip: return 0
        }
    }

    var coverChance: Double {
        switch self {
        case .dart: return 0.5
        case .wander: return 0.4
        case .hop: return 0.3
        case .swim: return 0.3
        case .flutter, .drift, .zip: return 0
        }
    }

    var pauseFraction: Double {
        switch self {
        case .swim: return 0.15
        case .dart: return 0.4
        case .wander: return 0.15
        case .flutter: return 0
        case .hop: return 0.3
        case .drift: return 0
        case .zip: return 0.6
        }
    }

    var distanceRange: ClosedRange<Double> {
        switch self {
        case .swim: return 0.15...0.3
        case .dart: return 0.25...0.5
        case .wander: return 0.15...0.3
        case .flutter: return 0.15...0.3
        case .hop: return 0.12...0.22
        case .drift: return 0.2...0.35
        case .zip: return 0.35...0.7
        }
    }

    /// Radians.
    var turnRange: ClosedRange<Double> {
        switch self {
        case .swim: return 0.25...0.7
        case .dart: return 0.3...2.4
        case .wander: return 0.2...1.0
        case .flutter: return 0.5...1.2
        case .hop: return 0.4...2.0
        case .drift: return 0.2...0.6
        case .zip: return 1.0...3.0
        }
    }
}
