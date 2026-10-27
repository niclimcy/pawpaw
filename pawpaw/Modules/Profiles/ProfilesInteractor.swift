//
//  ProfilesInteractor.swift
//  pawpaw
//

import Foundation

final class ProfilesInteractor: ProfilesInteractorInputProtocol {
    weak var presenter: ProfilesInteractorOutputProtocol?

    private let profileStorage: ProfileStorage
    private let makeStatsStorage: (UUID) -> StatsStorage

    init(profileStorage: ProfileStorage, makeStatsStorage: @escaping (UUID) -> StatsStorage) {
        self.profileStorage = profileStorage
        self.makeStatsStorage = makeStatsStorage
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

    func addProfile(name: String) {
        // Each new cat gets the next face in the list.
        let faces = CatProfile.emojiChoices
        let emoji = faces[profileStorage.profiles.count % faces.count]
        guard let profile = profileStorage.add(name: name, emoji: emoji) else { return }
        profileStorage.setActive(profile.id)
        fetchProfiles()
    }

    func renameProfile(id: UUID, name: String) {
        profileStorage.rename(id, to: name)
        fetchProfiles()
    }

    func deleteProfile(id: UUID) {
        profileStorage.delete(id)
        fetchProfiles()
    }
}
