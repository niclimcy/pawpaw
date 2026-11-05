//
//  ScoreStorage.swift
//  pawpaw
//

import Foundation

protocol ScoreStorage {
    func highScore(for mode: SessionMode) -> Int
    func saveHighScore(_ score: Int, for mode: SessionMode)
}

final class UserDefaultsScoreStorage: ScoreStorage {
    // TODO: To remove after swift bug is resolved.
    nonisolated deinit {}

    private let defaults: UserDefaults
    private let profileID: UUID

    init(defaults: UserDefaults = .standard, profileID: UUID) {
        self.defaults = defaults
        self.profileID = profileID
    }

    func reset() {
        for mode in SessionMode.allCases {
            defaults.removeObject(forKey: key(for: mode))
        }
    }

    func highScore(for mode: SessionMode) -> Int {
        defaults.integer(forKey: key(for: mode))
    }

    func saveHighScore(_ score: Int, for mode: SessionMode) {
        defaults.set(score, forKey: key(for: mode))
    }

    private func key(for mode: SessionMode) -> String {
        "pawpaw.\(profileID.uuidString).highScore.\(mode.rawValue)"
    }

    /// Where pre-profile versions kept the best score for `mode`; `nil` if it never had one.
    static func legacyKey(for mode: SessionMode) -> String? {
        guard mode.hasHighScore else { return nil }
        return mode == .standard ? "pawpaw.highScore" : "pawpaw.highScore.\(mode.rawValue)"
    }
}
