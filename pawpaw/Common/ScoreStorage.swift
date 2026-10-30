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
    private let defaults: UserDefaults
    private let profileID: UUID

    init(defaults: UserDefaults = .standard, profileID: UUID) {
        self.defaults = defaults
        self.profileID = profileID
    }

    func reset() {
        SessionMode.allCases.forEach { defaults.removeObject(forKey: key(for: $0)) }
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
}
