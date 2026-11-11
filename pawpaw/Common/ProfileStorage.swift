//
//  ProfileStorage.swift
//  pawpaw
//

import Foundation

protocol ProfileStorage {
    /// In insertion order; never empty.
    var profiles: [CatProfile] { get }
    var activeProfile: CatProfile { get }
    func setActive(_ id: UUID)
    @discardableResult func add(name: String, face: CatFace) -> CatProfile?
    /// An empty name keeps the old one.
    func update(_ id: UUID, name: String, face: CatFace)
    /// Ignored unless `CatProfile.isPlayable(disabledKinds:)` allows it.
    func setDisabledKinds(_ kinds: Set<TargetKind>, for id: UUID)
    /// Also removes the cat's scores and stats. The last cat can't be deleted.
    func delete(_ id: UUID)
}

final class UserDefaultsProfileStorage: ProfileStorage {
    // TODO: To remove after swift bug is resolved.
    nonisolated deinit {}

    private let defaults: UserDefaults
    private let makeScoreStorage: (UUID) -> ScoreStorage
    private let makeStatsStorage: (UUID) -> StatsStorage
    private let profilesKey = StorageKeys.profiles
    private let activeKey = StorageKeys.activeProfile

    init(
        defaults: UserDefaults = .standard,
        makeScoreStorage: ((UUID) -> ScoreStorage)? = nil,
        makeStatsStorage: ((UUID) -> StatsStorage)? = nil
    ) {
        self.defaults = defaults
        self.makeScoreStorage =
            makeScoreStorage ?? { UserDefaultsScoreStorage(defaults: defaults, profileID: $0) }
        self.makeStatsStorage =
            makeStatsStorage ?? { UserDefaultsStatsStorage(defaults: defaults, profileID: $0) }
        createDefaultProfileIfNeeded()
        repairProfilesIfNeeded()
    }

    var profiles: [CatProfile] {
        if let stored = storedProfiles(), !stored.isEmpty { return stored }
        // Fixed ID keeps scores and stats addressable if the data breaks after `init`.
        return [CatProfile(id: Self.fallbackID, name: CatProfile.defaultName)]
    }

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
        modify(id) {
            $0.name = cleanName ?? $0.name
            $0.face = face
        }
    }

    func setDisabledKinds(_ kinds: Set<TargetKind>, for id: UUID) {
        guard CatProfile.isPlayable(disabledKinds: kinds) else { return }
        modify(id) { $0.disabledKinds = kinds }
    }

    func delete(_ id: UUID) {
        let all = profiles
        guard all.count > 1, all.contains(where: { $0.id == id }) else { return }
        let wasActive = activeProfile.id == id
        let remaining = all.filter { $0.id != id }
        save(remaining)
        if wasActive { defaults.set(remaining[0].id.uuidString, forKey: activeKey) }
        makeScoreStorage(id).reset()
        makeStatsStorage(id).reset()
    }

    // MARK: Private
    private func save(_ profiles: [CatProfile]) {
        defaults.encode(profiles, forKey: profilesKey, failureMessage: "Couldn't save cat profiles")
    }

    private func modify(_ id: UUID, _ change: (inout CatProfile) -> Void) {
        save(
            profiles.map { profile in
                guard profile.id == id else { return profile }
                var copy = profile
                change(&copy)
                return copy
            })
    }

    private func storedProfiles() -> [CatProfile]? {
        defaults.decode(
            [CatProfile].self, forKey: profilesKey, failureMessage: "Couldn't read cat profiles")
    }

    /// Replaces an unreadable or empty list with a fixed-ID cat, so each read doesn't mint a new ID.
    private func repairProfilesIfNeeded() {
        if let stored = storedProfiles(), !stored.isEmpty { return }
        Log.storageNotice("Cat profiles were unreadable or empty; replaced with a default cat")
        save([CatProfile(id: Self.fallbackID, name: CatProfile.defaultName)])
        defaults.set(Self.fallbackID.uuidString, forKey: activeKey)
    }

    /// Migrates pre-profile scores and stats to the first cat. Legacy keys are left in place.
    private func createDefaultProfileIfNeeded() {
        guard defaults.data(forKey: profilesKey) == nil else { return }
        OnboardingState.recordIfNeeded(in: defaults)
        let first = CatProfile(name: CatProfile.defaultName)
        save([first])
        defaults.set(first.id.uuidString, forKey: activeKey)

        let scores = makeScoreStorage(first.id)
        for mode in SessionMode.allCases {
            guard let legacyKey = StorageKeys.legacyHighScore(for: mode) else { continue }
            let legacy = defaults.integer(forKey: legacyKey)
            if legacy > 0 { scores.saveHighScore(legacy, for: mode) }
        }
        if let legacyStats = defaults.data(forKey: StorageKeys.legacyStats) {
            defaults.set(legacyStats, forKey: StorageKeys.stats(for: first.id))
        }
    }
}
