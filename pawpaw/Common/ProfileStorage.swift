//
//  ProfileStorage.swift
//  pawpaw
//

import Foundation

protocol ProfileStorage {
    /// Every cat, in the order they were added. Never empty.
    var profiles: [CatProfile] { get }
    /// The cat that is playing now.
    var activeProfile: CatProfile { get }
    func setActive(_ id: UUID)
    @discardableResult func add(name: String, face: CatFace) -> CatProfile?
    /// Changes a cat's name and face. An empty name keeps the old one.
    func update(_ id: UUID, name: String, face: CatFace)
    /// Removes a cat and its scores and stats. The last cat can't be deleted.
    func delete(_ id: UUID)
}

final class UserDefaultsProfileStorage: ProfileStorage {
    private let defaults: UserDefaults
    private let profilesKey = "pawpaw.profiles"
    private let activeKey = "pawpaw.activeProfile"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        createDefaultProfileIfNeeded()
    }

    var profiles: [CatProfile] {
        guard let data = defaults.data(forKey: profilesKey),
              let profiles = try? JSONDecoder().decode([CatProfile].self, from: data),
              !profiles.isEmpty else { return [CatProfile(name: CatProfile.defaultName)] }
        return profiles
    }

    var activeProfile: CatProfile {
        let all = profiles
        let id = defaults.string(forKey: activeKey).flatMap(UUID.init(uuidString:))
        return all.first { $0.id == id } ?? all[0]
    }

    func setActive(_ id: UUID) {
        guard profiles.contains(where: { $0.id == id }) else { return }
        defaults.set(id.uuidString, forKey: activeKey)
    }

    @discardableResult
    func add(name: String, face: CatFace) -> CatProfile? {
        guard let name = CatProfile.cleaned(name) else { return nil }
        let profile = CatProfile(name: name, face: face)
        save(profiles + [profile])
        return profile
    }

    func update(_ id: UUID, name: String, face: CatFace) {
        let cleanName = CatProfile.cleaned(name)
        save(profiles.map { profile in
            var copy = profile
            if copy.id == id {
                copy.name = cleanName ?? copy.name
                copy.face = face
            }
            return copy
        })
    }

    func delete(_ id: UUID) {
        let all = profiles
        guard all.count > 1, all.contains(where: { $0.id == id }) else { return }
        let wasActive = activeProfile.id == id
        let remaining = all.filter { $0.id != id }
        save(remaining)
        if wasActive { defaults.set(remaining[0].id.uuidString, forKey: activeKey) }
        UserDefaultsScoreStorage(defaults: defaults, profileID: id).reset()
        UserDefaultsStatsStorage(defaults: defaults, profileID: id).reset()
    }

    // MARK: Private
    private func save(_ profiles: [CatProfile]) {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        defaults.set(data, forKey: profilesKey)
    }

    /// First launch with profiles: the existing scores and stats become the first cat's.
    /// The old keys stay in place, so nothing is lost if the owner goes back to an older build.
    private func createDefaultProfileIfNeeded() {
        guard defaults.data(forKey: profilesKey) == nil else { return }
        let first = CatProfile(name: CatProfile.defaultName)
        save([first])
        defaults.set(first.id.uuidString, forKey: activeKey)

        let scores = UserDefaultsScoreStorage(defaults: defaults, profileID: first.id)
        for mode in SessionMode.allCases where mode.hasHighScore {
            let legacyKey = mode == .standard ? "pawpaw.highScore" : "pawpaw.highScore.\(mode.rawValue)"
            let legacy = defaults.integer(forKey: legacyKey)
            if legacy > 0 { scores.saveHighScore(legacy, for: mode) }
        }
        if let legacyStats = defaults.data(forKey: "pawpaw.stats") {
            defaults.set(legacyStats, forKey: UserDefaultsStatsStorage.key(for: first.id))
        }
    }
}
