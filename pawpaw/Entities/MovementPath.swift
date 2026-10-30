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
    case slither
    case peck
    case scurry

    /// Fades in and out in place instead of entering and leaving via an edge.
    var surfaces: Bool {
        self == .swim
    }

    /// Weaves in S-curves along a smoothed path, like a wand toy's string.
    var slithers: Bool {
        self == .slither
    }

    /// Bobs its head forward during each pause.
    var pecks: Bool {
        self == .peck
    }

    /// Bobs up and down during a freeze, like a lizard doing push-ups.
    var doesPushUps: Bool {
        self == .scurry
    }

    /// Leaves in a fast straight flight across the field, sometimes before its path is done.
    var fliesOff: Bool {
        self == .peck
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
        case .slither: return 7...9
        case .peck: return 7...9
        case .scurry: return 4...6
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
        case .slither: return 0
        case .peck: return 0
        case .scurry: return 0.3
        }
    }

    var coverChance: Double {
        switch self {
        case .dart: return 0.5
        case .wander: return 0.4
        case .hop: return 0.3
        case .swim: return 0.3
        case .scurry: return 0.5
        case .flutter, .drift, .zip, .slither, .peck: return 0
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
        case .slither: return 0
        case .peck: return 0.45
        case .scurry: return 0.55
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
        case .slither: return 0.12...0.22
        case .peck: return 0.06...0.14
        case .scurry: return 0.2...0.4
        }
    }

    /// Radians. Slithering critters alternate left and right.
    var turnRange: ClosedRange<Double> {
        switch self {
        case .swim: return 0.25...0.7
        case .dart: return 0.3...2.4
        case .wander: return 0.2...1.0
        case .flutter: return 0.5...1.2
        case .hop: return 0.4...2.0
        case .drift: return 0.2...0.6
        case .zip: return 1.0...3.0
        case .slither: return 0.8...1.4
        case .peck: return 0.3...1.6
        case .scurry: return 0.3...2.0
        }
    }

    /// Radians of the quick jiggle during a freeze, like a whisker or tail flick. 0 for none.
    var twitchAngle: Double {
        switch self {
        case .dart: return 0.18
        case .wander: return 0.12
        case .hop: return 0.15
        case .flutter, .drift, .zip, .swim, .slither, .peck, .scurry: return 0
        }
    }

    /// Points of the tiny shuffle during a freeze. The laser's is the jitter of a hand-held pointer. 0 for none.
    var twitchShift: Double {
        switch self {
        case .dart: return 3
        case .wander: return 1.5
        case .hop: return 2.5
        case .zip: return 2
        case .flutter, .drift, .swim, .slither, .peck, .scurry: return 0
        }
    }
}
