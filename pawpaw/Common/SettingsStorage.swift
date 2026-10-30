//
//  SettingsStorage.swift
//  pawpaw
//

import Foundation

/// Device-wide settings shared by every cat.
protocol SettingsStorage: AnyObject {
    var selectedMode: SessionMode { get set }
    var selectedTheme: PlayfieldTheme { get set }
    var hasLearnedHoldToExit: Bool { get set }
    var hasCompletedOnboarding: Bool { get set }
}

final class UserDefaultsSettingsStorage: SettingsStorage {
    private let defaults: UserDefaults
    // Legacy keys; keep them so existing saved choices carry over.
    private let modeKey = "pawpaw.selectedMode"
    private let themeKey = "pawpaw.selectedTheme"
    private let holdToExitKey = "pawpaw.hasLearnedHoldToExit"
    private let onboardingKey = "pawpaw.hasCompletedOnboarding"

    /// Create before any `UserDefaultsProfileStorage` on launch: that creates a cat,
    /// which would make a fresh install look like an existing one.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        recordOnboardingStateIfNeeded()
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

    var hasLearnedHoldToExit: Bool {
        get {
            defaults.bool(forKey: holdToExitKey)
        }
        set {
            defaults.set(newValue, forKey: holdToExitKey)
        }
    }

    var hasCompletedOnboarding: Bool {
        get {
            defaults.bool(forKey: onboardingKey)
        }
        set {
            defaults.set(newValue, forKey: onboardingKey)
        }
    }

    /// Saved once so quitting mid-onboarding doesn't skip it next launch. Devices that
    /// already have cats, scores or stats skip onboarding.
    private func recordOnboardingStateIfNeeded() {
        guard defaults.object(forKey: onboardingKey) == nil else { return }
        let existingKeys = ["pawpaw.profiles", "pawpaw.stats", "pawpaw.highScore"]
        let hasExistingData = existingKeys.contains { defaults.object(forKey: $0) != nil }
        defaults.set(hasExistingData, forKey: onboardingKey)
    }
}
