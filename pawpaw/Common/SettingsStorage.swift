//
//  SettingsStorage.swift
//  pawpaw
//

import Foundation

/// Device-wide settings shared by every cat.
protocol SettingsStorage: AnyObject {
    var selectedMode: SessionMode { get set }
    var selectedTheme: PlayfieldTheme { get set }
    var afterRound: AfterRoundMode { get set }
    var hasLearnedHoldToExit: Bool { get set }
    var hasCompletedOnboarding: Bool { get set }
}

final class UserDefaultsSettingsStorage: SettingsStorage {
    // TODO: To remove after swift bug is resolved.
    nonisolated deinit {}

    private let defaults: UserDefaults
    private let defaultMode: SessionMode

    init(
        defaults: UserDefaults = .standard,
        defaultMode: SessionMode = PlayfieldTuning.current.defaultMode
    ) {
        self.defaults = defaults
        self.defaultMode = defaultMode
        OnboardingState.recordIfNeeded(in: defaults)
    }

    var selectedMode: SessionMode {
        get {
            defaults.string(forKey: StorageKeys.selectedMode).flatMap(SessionMode.init(rawValue:))
                ?? defaultMode
        }
        set {
            defaults.set(newValue.rawValue, forKey: StorageKeys.selectedMode)
        }
    }

    var selectedTheme: PlayfieldTheme {
        get {
            defaults.string(forKey: StorageKeys.selectedTheme)
                .flatMap(PlayfieldTheme.init(rawValue:)) ?? .wood
        }
        set {
            defaults.set(newValue.rawValue, forKey: StorageKeys.selectedTheme)
        }
    }

    var afterRound: AfterRoundMode {
        get {
            defaults.string(forKey: StorageKeys.afterRound).flatMap(AfterRoundMode.init(rawValue:))
                ?? .keepPlaying
        }
        set {
            defaults.set(newValue.rawValue, forKey: StorageKeys.afterRound)
        }
    }

    var hasLearnedHoldToExit: Bool {
        get {
            defaults.bool(forKey: StorageKeys.hasLearnedHoldToExit)
        }
        set {
            defaults.set(newValue, forKey: StorageKeys.hasLearnedHoldToExit)
        }
    }

    var hasCompletedOnboarding: Bool {
        get {
            defaults.bool(forKey: StorageKeys.hasCompletedOnboarding)
        }
        set {
            defaults.set(newValue, forKey: StorageKeys.hasCompletedOnboarding)
        }
    }
}
