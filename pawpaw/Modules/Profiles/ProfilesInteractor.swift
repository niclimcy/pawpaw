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

    func addProfile(name: String, face: CatFace) {
        guard let profile = profileStorage.add(name: name, face: face) else { return }
        profileStorage.setActive(profile.id)
        fetchProfiles()
    }

    func updateProfile(id: UUID, name: String, face: CatFace) {
        profileStorage.update(id, name: name, face: face)
        fetchProfiles()
    }

    func deleteProfile(id: UUID) {
        profileStorage.delete(id)
        fetchProfiles()
    }
}
