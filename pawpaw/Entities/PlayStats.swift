//
//  PlayStats.swift
//  pawpaw
//

import Foundation

struct PlayStats: Codable, Equatable {
    var totalRounds = 0
    var totalCatches = 0
    /// Keyed by `TargetKind.rawValue`.
    var catchesByKind: [String: Int] = [:]
    /// Keyed by `PlayStats.dayKey(for:)`.
    var roundsByDay: [String: Int] = [:]

    /// Ties go to the earliest case in `TargetKind`, so the result is stable.
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

    /// Oldest first, ending today.
    func recentRounds(days: Int, endingOn today: Date = Date(), calendar: Calendar = .current) -> [(date: Date, rounds: Int)] {
        (0..<days).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return (date, roundsByDay[Self.dayKey(for: date, calendar: calendar)] ?? 0)
        }
    }

    /// `isNewRound` is false for later parts of an interrupted round, so it isn't counted twice.
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
