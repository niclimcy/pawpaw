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

    /// The critter caught most often, if any.
    var favoriteKind: TargetKind? {
        catchesByKind
            .filter { $0.value > 0 }
            .max { $0.value < $1.value }
            .flatMap { TargetKind(rawValue: $0.key) }
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

    /// Adds one finished session to the totals.
    mutating func record(catches: [TargetKind: Int], on date: Date = Date(), calendar: Calendar = .current) {
        totalRounds += 1
        for (kind, count) in catches {
            totalCatches += count
            catchesByKind[kind.rawValue, default: 0] += count
        }
        roundsByDay[Self.dayKey(for: date, calendar: calendar), default: 0] += 1
    }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
