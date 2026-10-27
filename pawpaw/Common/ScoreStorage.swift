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

final class UserDefaultsScoreStorage: ScoreStorage {
    private let defaults: UserDefaults
    private let modeKey = "pawpaw.selectedMode"
    private let themeKey = "pawpaw.selectedTheme"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
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

    /// The 60 second mode keeps the original key, so existing best scores survive the update.
    private func key(for mode: SessionMode) -> String {
        mode == .standard ? "pawpaw.highScore" : "pawpaw.highScore.\(mode.rawValue)"
    }
}
