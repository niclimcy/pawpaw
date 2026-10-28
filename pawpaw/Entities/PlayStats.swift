//
//  PlayStats.swift
//  pawpaw
//

import Foundation

/// Lifetime play history. Owners can use it to spot changes in a cat's mood or energy.
struct PlayStats: Codable, Equatable {
    var totalRounds = 0
    var totalCatches = 0
    /// Catches per critter, keyed by `TargetKind.rawValue`.
    var catchesByKind: [String: Int] = [:]
    /// Rounds played per day, keyed by `PlayStats.dayKey(for:)`.
    var roundsByDay: [String: Int] = [:]

    /// The critter caught most often, if any. A tie goes to the critter listed first in `TargetKind`,
    /// so the favorite doesn't change from one launch to the next.
    var favoriteKind: TargetKind? {
        var best: (kind: TargetKind, catches: Int)?
        for kind in TargetKind.allCases {
            let count = catches(of: kind)
            if count > (best?.catches ?? 0) { best = (kind, count) }
        }
        return best?.kind
    }

    func catches(of kind: TargetKind) -> Int {
        catchesByKind[kind.rawValue] ?? 0
    }

    /// Rounds played on each of the last `days` days, oldest first, ending today.
    func recentRounds(days: Int, endingOn today: Date = Date(), calendar: Calendar = .current) -> [(date: Date, rounds: Int)] {
        (0..<days).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return (date, roundsByDay[Self.dayKey(for: date, calendar: calendar)] ?? 0)
        }
    }

    /// Adds catches to the totals. `isNewRound` is false when adding more of a round that was already
    /// counted (it was saved when the app was interrupted), so the round isn't counted twice.
    mutating func record(
        catches: [TargetKind: Int],
        isNewRound: Bool = true,
        on date: Date = Date(),
        calendar: Calendar = .current
    ) {
        for (kind, count) in catches {
            totalCatches += count
            catchesByKind[kind.rawValue, default: 0] += count
        }
        guard isNewRound else { return }
        totalRounds += 1
        roundsByDay[Self.dayKey(for: date, calendar: calendar), default: 0] += 1
    }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
