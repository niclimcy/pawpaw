//
//  StatsStorage.swift
//  pawpaw
//

import Foundation

protocol StatsStorage {
    var stats: PlayStats { get }
    /// Adds catches to the lifetime totals. A round is saved in parts when it is interrupted, so only
    /// the first part passes `isNewRound`, and the round is counted once.
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

    /// Each cat has its own play history.
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
