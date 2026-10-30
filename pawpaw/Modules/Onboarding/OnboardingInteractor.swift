//
//  OnboardingInteractor.swift
//  pawpaw
//

import Foundation

final class OnboardingInteractor: OnboardingInteractorInputProtocol {
    private let profileStorage: ProfileStorage
    private let settings: SettingsStorage

    init(profileStorage: ProfileStorage, settings: SettingsStorage) {
        self.profileStorage = profileStorage
        self.settings = settings
    }

    var activeProfile: CatProfile {
        profileStorage.activeProfile
    }

    /// Renames the first cat rather than adding one, so there's no leftover "My Cat".
    func saveCat(name: String, face: CatFace) {
        profileStorage.update(profileStorage.activeProfile.id, name: name, face: face)
    }

    func completeOnboarding() {
        settings.hasCompletedOnboarding = true
    }
}
