//
//  OnboardingState.swift
//  pawpaw
//

import Foundation

enum OnboardingState {
    /// Saved once so quitting mid-onboarding doesn't skip it next launch. Devices that
    /// already have cats, scores or stats skip onboarding. Whoever runs first, settings
    /// or profiles, records it before the first cat is created.
    static func recordIfNeeded(in defaults: UserDefaults) {
        guard defaults.object(forKey: StorageKeys.hasCompletedOnboarding) == nil else { return }
        let hasExistingData = StorageKeys.existingDataKeys.contains {
            defaults.object(forKey: $0) != nil
        }
        defaults.set(hasExistingData, forKey: StorageKeys.hasCompletedOnboarding)
    }
}
