//
//  StatsStorage.swift
//  pawpaw
//

import Foundation

protocol StatsStorage {
    var stats: PlayStats { get }
    /// Interrupted rounds are saved in parts; only the first part passes `isNewRound`.
    func record(catches: [TargetKind: Int], isNewRound: Bool)
    func reset()
}

final class UserDefaultsStatsStorage: StatsStorage {
    // TODO: To remove after swift bug is resolved.
    nonisolated deinit {}

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, profileID: UUID) {
        self.defaults = defaults
        self.key = StorageKeys.stats(for: profileID)
    }

    var stats: PlayStats {
        defaults.decode(
            PlayStats.self, forKey: key,
            failureMessage: "Couldn't read play stats, starting from zero") ?? PlayStats()
    }

    func record(catches: [TargetKind: Int], isNewRound: Bool) {
        var updated = stats
        updated.record(catches: catches, isNewRound: isNewRound)
        save(updated)
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }

    private func save(_ stats: PlayStats) {
        defaults.encode(stats, forKey: key, failureMessage: "Couldn't save play stats")
    }
}
