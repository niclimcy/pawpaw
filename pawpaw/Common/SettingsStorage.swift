//
//  SettingsStorage.swift
//  pawpaw
//

import Foundation

/// Device-wide settings shared by every cat.
protocol SettingsStorage: AnyObject {
    var selectedMode: SessionMode { get set }
    var selectedTheme: PlayfieldTheme { get set }
}

final class UserDefaultsSettingsStorage: SettingsStorage {
    private let defaults: UserDefaults
    // Legacy keys; keep them so existing saved choices carry over.
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
