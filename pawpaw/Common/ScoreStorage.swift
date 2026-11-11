//
//  ScoreStorage.swift
//  pawpaw
//

import Foundation

protocol ScoreStorage {
    func highScore(for mode: SessionMode) -> Int
    func saveHighScore(_ score: Int, for mode: SessionMode)
    func reset()
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
        StorageKeys.highScore(for: mode, profileID: profileID)
    }
}
