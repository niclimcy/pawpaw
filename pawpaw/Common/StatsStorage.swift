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
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, profileID: UUID) {
        self.defaults = defaults
        self.key = Self.key(for: profileID)
    }

    static func key(for profileID: UUID) -> String {
        "pawpaw.\(profileID.uuidString).stats"
    }

    var stats: PlayStats {
        guard let data = defaults.data(forKey: key) else { return PlayStats() }
        do {
            return try JSONDecoder().decode(PlayStats.self, from: data)
        } catch {
            Log.storageFailure("Couldn't read play stats, starting from zero", error: error)
            return PlayStats()
        }
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
        do {
            defaults.set(try JSONEncoder().encode(stats), forKey: key)
        } catch {
            Log.storageFailure("Couldn't save play stats", error: error)
        }
    }
}
