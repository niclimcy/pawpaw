//
//  ScoreStorage.swift
//  pawpaw
//

import Foundation

protocol ScoreStorage {
    /// The mode the owner picked on the Home screen.
    var selectedMode: SessionMode { get set }
    /// The playfield background picked on the Home screen.
    var selectedTheme: PlayfieldTheme { get set }
    func highScore(for mode: SessionMode) -> Int
    func saveHighScore(_ score: Int, for mode: SessionMode)
}

/// The mode and theme are device-wide choices; best scores belong to one cat.
final class UserDefaultsScoreStorage: ScoreStorage {
    private let defaults: UserDefaults
    private let profileID: UUID
    private let modeKey = "pawpaw.selectedMode"
    private let themeKey = "pawpaw.selectedTheme"

    init(defaults: UserDefaults = .standard, profileID: UUID) {
        self.defaults = defaults
        self.profileID = profileID
    }

    /// Forgets every best score of this cat.
    func reset() {
        SessionMode.allCases.forEach { defaults.removeObject(forKey: key(for: $0)) }
    }

    var selectedMode: SessionMode {
        get {
            defaults.string(forKey: modeKey).flatMap(SessionMode.init(rawValue:)) ?? .standard
        }
        set {
            defaults.set(newValue.rawValue, forKey: modeKey)
        }
    }

    var selectedTheme: PlayfieldTheme {
        get {
            defaults.string(forKey: themeKey).flatMap(PlayfieldTheme.init(rawValue:)) ?? .wood
        }
        set {
            defaults.set(newValue.rawValue, forKey: themeKey)
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
}
