//
//  MockStorages.swift
//  pawpawTests
//

import Foundation

@testable import pawpaw

@MainActor
final class MockScoreStorage: ScoreStorage {
    var scores: [SessionMode: Int] = [:]
    private(set) var saved: [(score: Int, mode: SessionMode)] = []

    func highScore(for mode: SessionMode) -> Int {
        scores[mode] ?? 0
    }

    func saveHighScore(_ score: Int, for mode: SessionMode) {
        saved.append((score, mode))
        scores[mode] = score
    }
}

@MainActor
final class MockStatsStorage: StatsStorage {
    var stats = PlayStats()
    private(set) var recorded: [(catches: [TargetKind: Int], isNewRound: Bool)] = []
    private(set) var resetCount = 0

    func record(catches: [TargetKind: Int], isNewRound: Bool) {
        recorded.append((catches, isNewRound))
        stats.record(catches: catches, isNewRound: isNewRound)
    }

    func reset() {
        resetCount += 1
        stats = PlayStats()
    }
}

@MainActor
final class MockSettingsStorage: SettingsStorage {
    var selectedMode: SessionMode = .standard
    var selectedTheme: PlayfieldTheme = .wood
    var afterRound: AfterRoundMode = .keepPlaying
    var hasLearnedHoldToExit = false
    var hasCompletedOnboarding = false
}

/// In-memory profile storage that follows the `ProfileStorage` contract.
@MainActor
final class MockProfileStorage: ProfileStorage {
    var profiles: [CatProfile]
    var activeID: UUID
    private(set) var updates: [(id: UUID, name: String, face: CatFace)] = []

    init(profiles: [CatProfile] = [CatProfile(name: "Tom")]) {
        self.profiles = profiles
        self.activeID = profiles[0].id
    }

    var activeProfile: CatProfile {
        profiles.first { $0.id == activeID } ?? profiles[0]
    }

    func setActive(_ id: UUID) {
        guard profiles.contains(where: { $0.id == id }) else { return }
        activeID = id
    }

    @discardableResult
    func add(name: String, face: CatFace) -> CatProfile? {
        guard let name = CatProfile.cleaned(name) else { return nil }
        let profile = CatProfile(name: name, face: face)
        profiles.append(profile)
        return profile
    }

    func update(_ id: UUID, name: String, face: CatFace) {
        updates.append((id, name, face))
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[index].name = CatProfile.cleaned(name) ?? profiles[index].name
        profiles[index].face = face
    }

    func setDisabledKinds(_ kinds: Set<TargetKind>, for id: UUID) {
        guard CatProfile.isPlayable(disabledKinds: kinds),
            let index = profiles.firstIndex(where: { $0.id == id })
        else { return }
        profiles[index].disabledKinds = kinds
    }

    func delete(_ id: UUID) {
        guard profiles.count > 1 else { return }
        profiles.removeAll { $0.id == id }
        if activeID == id { activeID = profiles[0].id }
    }
}
