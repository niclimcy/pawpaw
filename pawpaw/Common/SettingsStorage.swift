//
//  SettingsStorage.swift
//  pawpaw
//

import Foundation

/// Device-wide choices from the Home screen, shared by every cat.
protocol SettingsStorage: AnyObject {
    /// The session length the owner picked on the Home screen.
    var selectedMode: SessionMode { get set }
    /// The playfield background picked on the Home screen.
    var selectedTheme: PlayfieldTheme { get set }
}

final class UserDefaultsSettingsStorage: SettingsStorage {
    private let defaults: UserDefaults
    // The keys are unchanged from when these lived in the score storage, so saved choices carry over.
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
}
