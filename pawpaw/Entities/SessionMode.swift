//
//  SessionMode.swift
//  pawpaw
//

import Foundation

enum SessionMode: String, CaseIterable {
    case short
    case standard
    case long
    case relaxed

    /// Seconds in a round; `nil` means no timer.
    var duration: Int? {
        switch self {
        case .short: return 30
        case .standard: return 60
        case .long: return 120
        case .relaxed: return nil
        }
    }

    var title: String {
        switch self {
        case .short: return "30s"
        case .standard: return "60s"
        case .long: return "2 min"
        case .relaxed: return "Relaxed"
        }
    }

    var hasHighScore: Bool {
        duration != nil
    }
}
