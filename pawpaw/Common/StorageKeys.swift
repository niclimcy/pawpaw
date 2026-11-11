//
//  StorageKeys.swift
//  pawpaw
//

import Foundation

/// Every `UserDefaults` key the app writes. Existing installs depend on these exact strings.
enum StorageKeys {
    static let profiles = "pawpaw.profiles"
    static let activeProfile = "pawpaw.activeProfile"
    static let selectedMode = "pawpaw.selectedMode"
    static let selectedTheme = "pawpaw.selectedTheme"
    static let afterRound = "pawpaw.afterRound"
    static let hasLearnedHoldToExit = "pawpaw.hasLearnedHoldToExit"
    static let hasCompletedOnboarding = "pawpaw.hasCompletedOnboarding"

    static func highScore(for mode: SessionMode, profileID: UUID) -> String {
        "pawpaw.\(profileID.uuidString).highScore.\(mode.rawValue)"
    }

    static func stats(for profileID: UUID) -> String {
        "pawpaw.\(profileID.uuidString).stats"
    }

    /// Where pre-profile versions kept all play stats.
    static let legacyStats = "pawpaw.stats"

    /// Where pre-profile versions kept the best score for `mode`; `nil` if it never had one.
    static func legacyHighScore(for mode: SessionMode) -> String? {
        guard mode.hasHighScore else { return nil }
        return mode == .standard ? "pawpaw.highScore" : "pawpaw.highScore.\(mode.rawValue)"
    }

    /// Keys whose presence means the device was used before onboarding was recorded.
    static var existingDataKeys: [String] {
        [profiles, legacyStats] + SessionMode.allCases.compactMap(legacyHighScore(for:))
    }
}
