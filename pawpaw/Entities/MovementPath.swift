//
//  MovementPath.swift
//  pawpaw
//

import CoreGraphics
import Foundation

/// One stretch of a critter's journey: travel to a point, then optionally freeze there.
struct PathLeg: Equatable {
    /// Normalized (0...1) destination.
    let destination: CGPoint
    let travel: TimeInterval
    /// Time spent frozen at the destination before the next leg starts.
    let pause: TimeInterval
    /// The critter runs off the nearest edge during the freeze, then comes back.
    let hides: Bool
    /// The critter runs off the edge of the field and out of sight, ending its journey.
    var exits: Bool = false
}

/// How a critter moves. Real prey moves in bursts and changes direction, which holds a cat's attention.
enum MovementStyle {
    /// Quick dashes with long freezes (mouse).
    case dart
    /// Slow meandering with short stops (bug).
    case wander
    /// Constant zig-zagging arcs, no stops (butterfly).
    case flutter
    /// Short sudden hops with brief stops (cricket).
    case hop
    /// Slow, gentle curves that never stop, like a feather on a breeze.
    case drift

    var legCount: ClosedRange<Int> {
        switch self {
        case .dart: return 3...4
        case .wander: return 4...5
        case .flutter: return 6...8
        case .hop: return 6...8
        case .drift: return 4...5
        }
    }

    /// Chance that a long enough freeze is spent out of sight beyond the edge.
    var hideChance: Double {
        switch self {
        case .dart: return 0.6
        case .wander: return 0.3
        case .flutter: return 0
        case .hop: return 0.2
        case .drift: return 0
        }
    }

    /// Share of the lifetime spent frozen between legs.
    var pauseFraction: Double {
        switch self {
        case .dart: return 0.4
        case .wander: return 0.15
        case .flutter: return 0
        case .hop: return 0.3
        case .drift: return 0
        }
    }

    /// Normalized distance covered by one leg.
    var distanceRange: ClosedRange<Double> {
        switch self {
        case .dart: return 0.25...0.5
        case .wander: return 0.15...0.3
        case .flutter: return 0.15...0.3
        case .hop: return 0.12...0.22
        case .drift: return 0.2...0.35
        }
    }

    /// Radians the heading changes between legs.
    var turnRange: ClosedRange<Double> {
        switch self {
        case .dart: return 0.3...2.4
        case .wander: return 0.2...1.0
        case .flutter: return 0.5...1.2
        case .hop: return 0.4...2.0
        case .drift: return 0.2...0.6
        }
    }
}
