//
//  SessionMode.swift
//  pawpaw
//

import Foundation

/// How long a play session lasts. Short rounds suit kittens and seniors; relaxed play never ends.
enum SessionMode: String, CaseIterable {
    case short
    case standard
    case long
    case relaxed

    /// Seconds in a round, or `nil` when there is no timer.
    var duration: Int? {
        switch self {
        case .short: return 30
        case .standard: return 60
        case .long: return 120
        case .relaxed: return nil
        }
    }

    /// Short label for the mode picker.
    var title: String {
        switch self {
        case .short: return "30s"
        case .standard: return "60s"
        case .long: return "2 min"
        case .relaxed: return "Relaxed"
        }
    }

    /// Relaxed play has no end, so there is no score to beat.
    var hasHighScore: Bool {
        duration != nil
    }
}
