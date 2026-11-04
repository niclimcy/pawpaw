//
//  AfterRoundMode.swift
//  pawpaw
//

import Foundation

/// What catching the critter that roams the results card does after a timed round.
enum AfterRoundMode: String, CaseIterable {
    /// Every catch starts another round.
    case keepPlaying
    /// Catches start up to `roundLimit` rounds in a row, then the cat gets one last, easy catch.
    case limited
    /// Only the last, easy catch; owners start any new round.
    case stop

    static let roundLimit = 3

    var title: String {
        switch self {
        case .keepPlaying: return "Keep going"
        case .limited: return "\(Self.roundLimit) rounds"
        case .stop: return "Stop"
        }
    }

    /// Whether a catch starts another round, after `autoRounds` rounds in a row were started that way.
    func continues(afterAutoRounds autoRounds: Int) -> Bool {
        switch self {
        case .keepPlaying: return true
        case .limited: return autoRounds < Self.roundLimit
        case .stop: return false
        }
    }
}
