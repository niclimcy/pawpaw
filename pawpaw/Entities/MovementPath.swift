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
}

/// How a critter moves. Real prey moves in bursts and changes direction, which holds a cat's attention.
enum MovementStyle {
    /// Quick dashes with long freezes (mouse).
    case dart
    /// Slow meandering with short stops (bug).
    case wander
    /// Constant zig-zagging arcs, no stops (butterfly).
    case flutter

    var legCount: ClosedRange<Int> {
        switch self {
        case .dart: return 3...4
        case .wander: return 4...5
        case .flutter: return 6...8
        }
    }

    /// Share of the lifetime spent frozen between legs.
    var pauseFraction: Double {
        switch self {
        case .dart: return 0.4
        case .wander: return 0.15
        case .flutter: return 0
        }
    }

    /// Normalized distance covered by one leg.
    var distanceRange: ClosedRange<Double> {
        switch self {
        case .dart: return 0.25...0.5
        case .wander: return 0.15...0.3
        case .flutter: return 0.15...0.3
        }
    }

    /// Radians the heading changes between legs.
    var turnRange: ClosedRange<Double> {
        switch self {
        case .dart: return 0.3...2.4
        case .wander: return 0.2...1.0
        case .flutter: return 0.5...1.2
        }
    }
}
