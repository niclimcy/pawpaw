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
    /// Sets which critters stay out of a cat's rounds. Ignored unless `CatProfile.isPlayable` allows it,
    /// so at least one critter that lives on every background always stays on.
    func setDisabledKinds(_ kinds: Set<TargetKind>, for id: UUID)
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
        repairProfilesIfNeeded()
    }

    var profiles: [CatProfile] {
        if let stored = storedProfiles(), !stored.isEmpty { return stored }
        // Only reachable if the data broke after `init` repaired it. The fixed ID keeps the active cat
        // stable, so scores and stats saved meanwhile can still be found.
        return [CatProfile(id: Self.fallbackID, name: CatProfile.defaultName)]
    }

    /// Used for the stand-in cat when the saved list can't be read.
    static let fallbackID = UUID(uuidString: "00000000-0000-0000-0000-00000000CA75")!

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

    func setDisabledKinds(_ kinds: Set<TargetKind>, for id: UUID) {
        // Turning off every critter that lives on all backgrounds would leave some playfields empty, so ignore that.
        guard CatProfile.isPlayable(disabledKinds: kinds) else { return }
        save(profiles.map { profile in
            var copy = profile
            if copy.id == id { copy.disabledKinds = kinds }
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
        do {
            defaults.set(try JSONEncoder().encode(profiles), forKey: profilesKey)
        } catch {
            Log.storageFailure("Couldn't save cat profiles", error: error)
        }
    }

    /// The saved cats, or `nil` when there are none or they can't be read.
    private func storedProfiles() -> [CatProfile]? {
        guard let data = defaults.data(forKey: profilesKey) else { return nil }
        do {
            return try JSONDecoder().decode([CatProfile].self, from: data)
        } catch {
            Log.storageFailure("Couldn't read cat profiles", error: error)
            return nil
        }
    }

    /// If the saved list is unreadable or empty, replace it once with one cat that has a fixed ID.
    /// Otherwise every read would make a cat with a new ID, and anything saved for it would be lost.
    private func repairProfilesIfNeeded() {
        if let stored = storedProfiles(), !stored.isEmpty { return }
        Log.storageNotice("Cat profiles were unreadable or empty; replaced with a default cat")
        save([CatProfile(id: Self.fallbackID, name: CatProfile.defaultName)])
        defaults.set(Self.fallbackID.uuidString, forKey: activeKey)
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
