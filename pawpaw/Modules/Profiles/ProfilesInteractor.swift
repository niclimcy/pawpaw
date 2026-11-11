//
//  ProfilesInteractor.swift
//  pawpaw
//

import Foundation

final class ProfilesInteractor: ProfilesInteractorInputProtocol {
    // TODO: To remove after swift bug is resolved.
    nonisolated deinit {}

    weak var presenter: ProfilesInteractorOutputProtocol?

    private let profileStorage: ProfileStorage
    private let settings: SettingsStorage
    private let makeStatsStorage: (UUID) -> StatsStorage

    init(
        profileStorage: ProfileStorage, settings: SettingsStorage,
        makeStatsStorage: @escaping (UUID) -> StatsStorage
    ) {
        self.profileStorage = profileStorage
        self.settings = settings
        self.makeStatsStorage = makeStatsStorage
    }

    func fetchTheme() {
        presenter?.didFetchTheme(settings.selectedTheme)
    }

    func fetchProfiles() {
        let entries = profileStorage.profiles.map {
            ProfileEntry(profile: $0, favorite: makeStatsStorage($0.id).stats.favoriteKind)
        }
        presenter?.didFetchProfiles(entries, activeID: profileStorage.activeProfile.id)
    }

    func selectProfile(id: UUID) {
        profileStorage.setActive(id)
        fetchProfiles()
    }

    func addProfile(name: String, face: CatFace, disabledKinds: Set<TargetKind>) {
        guard let profile = profileStorage.add(name: name, face: face) else { return }
        profileStorage.setDisabledKinds(disabledKinds, for: profile.id)
        profileStorage.setActive(profile.id)
        fetchProfiles()
    }

    func updateProfile(id: UUID, name: String, face: CatFace, disabledKinds: Set<TargetKind>) {
        profileStorage.update(id, name: name, face: face)
        profileStorage.setDisabledKinds(disabledKinds, for: id)
        fetchProfiles()
    }

    func deleteProfile(id: UUID) {
        profileStorage.delete(id)
        fetchProfiles()
    }
}
