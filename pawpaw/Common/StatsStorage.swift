//
//  StatsStorage.swift
//  pawpaw
//

import Foundation

protocol StatsStorage {
    var stats: PlayStats { get }
    /// Adds a finished session's catches to the lifetime totals.
    func record(catches: [TargetKind: Int])
    func reset()
}

final class UserDefaultsStatsStorage: StatsStorage {
    private let defaults: UserDefaults
    private let key = "pawpaw.stats"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var stats: PlayStats {
        guard let data = defaults.data(forKey: key),
              let stats = try? JSONDecoder().decode(PlayStats.self, from: data) else { return PlayStats() }
        return stats
    }

    func record(catches: [TargetKind: Int]) {
        var updated = stats
        updated.record(catches: catches)
        save(updated)
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }

    private func save(_ stats: PlayStats) {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        defaults.set(data, forKey: key)
    }
}
