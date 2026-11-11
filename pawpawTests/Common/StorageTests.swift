//
//  StorageTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class StorageTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        defaults = makeTestDefaults()
    }

    // MARK: Scores

    func testScoresStartAtZeroAndPersist() {
        let id = UUID()
        let scores = UserDefaultsScoreStorage(defaults: defaults, profileID: id)
        XCTAssertEqual(scores.highScore(for: .short), 0)
        scores.saveHighScore(120, for: .short)
        XCTAssertEqual(
            UserDefaultsScoreStorage(defaults: defaults, profileID: id).highScore(for: .short), 120)
        XCTAssertEqual(scores.highScore(for: .long), 0, "Modes are separate")
    }

    func testScoresAreSeparatePerCat() {
        let a = UserDefaultsScoreStorage(defaults: defaults, profileID: UUID())
        let b = UserDefaultsScoreStorage(defaults: defaults, profileID: UUID())
        a.saveHighScore(40, for: .standard)
        XCTAssertEqual(b.highScore(for: .standard), 0)
    }

    func testScoreResetClearsEveryMode() {
        let scores = UserDefaultsScoreStorage(defaults: defaults, profileID: UUID())
        for mode in SessionMode.allCases { scores.saveHighScore(10, for: mode) }
        scores.reset()
        for mode in SessionMode.allCases { XCTAssertEqual(scores.highScore(for: mode), 0) }
    }

    // MARK: Stats

    func testStatsRecordAndPersist() {
        let id = UUID()
        let stats = UserDefaultsStatsStorage(defaults: defaults, profileID: id)
        XCTAssertEqual(stats.stats, PlayStats())
        stats.record(catches: [.mouse: 2], isNewRound: true)
        stats.record(catches: [.mouse: 1], isNewRound: false)

        let reloaded = UserDefaultsStatsStorage(defaults: defaults, profileID: id).stats
        XCTAssertEqual(reloaded.totalRounds, 1)
        XCTAssertEqual(reloaded.catches(of: .mouse), 3)
    }

    func testStatsAreSeparatePerCatAndReset() {
        let a = UserDefaultsStatsStorage(defaults: defaults, profileID: UUID())
        let b = UserDefaultsStatsStorage(defaults: defaults, profileID: UUID())
        a.record(catches: [.bug: 1], isNewRound: true)
        XCTAssertEqual(b.stats, PlayStats())
        a.reset()
        XCTAssertEqual(a.stats, PlayStats())
    }

    func testCorruptStatsStartFromZero() {
        let id = UUID()
        defaults.set(Data("garbage".utf8), forKey: StorageKeys.stats(for: id))
        let stats = UserDefaultsStatsStorage(defaults: defaults, profileID: id)
        XCTAssertEqual(stats.stats, PlayStats())
        stats.record(catches: [.bug: 1], isNewRound: true)
        XCTAssertEqual(stats.stats.totalCatches, 1, "Recording replaces the corrupt data")
    }

    // MARK: Settings

    func testSettingsDefaults() {
        let settings = UserDefaultsSettingsStorage(defaults: defaults, defaultMode: .standard)
        XCTAssertEqual(settings.selectedMode, .standard)
        XCTAssertEqual(settings.selectedTheme, .wood)
        XCTAssertEqual(settings.afterRound, .keepPlaying)
        XCTAssertFalse(settings.hasLearnedHoldToExit)
    }

    func testSelectedModeDefaultsToTheDeviceDefaultMode() {
        XCTAssertEqual(PlayfieldTuning.standard.defaultMode, .standard, "iPad")
        XCTAssertEqual(PlayfieldTuning.pocket.defaultMode, .short, "iPhone")
        for tuning in [PlayfieldTuning.standard, .pocket] {
            let settings = UserDefaultsSettingsStorage(
                defaults: makeTestDefaults(), defaultMode: tuning.defaultMode)
            XCTAssertEqual(settings.selectedMode, tuning.defaultMode)
        }
    }

    func testSettingsPersist() {
        let settings = UserDefaultsSettingsStorage(defaults: defaults)
        settings.selectedMode = .relaxed
        settings.selectedTheme = .pond
        settings.afterRound = .limited
        settings.hasLearnedHoldToExit = true

        let reloaded = UserDefaultsSettingsStorage(defaults: defaults)
        XCTAssertEqual(reloaded.selectedMode, .relaxed)
        XCTAssertEqual(reloaded.selectedTheme, .pond)
        XCTAssertEqual(reloaded.afterRound, .limited)
        XCTAssertTrue(reloaded.hasLearnedHoldToExit)
    }

    func testUnknownStoredValuesFallBack() {
        defaults.set("hyper", forKey: "pawpaw.selectedMode")
        defaults.set("lava", forKey: "pawpaw.selectedTheme")
        defaults.set("forever", forKey: "pawpaw.afterRound")
        let settings = UserDefaultsSettingsStorage(defaults: defaults, defaultMode: .short)
        XCTAssertEqual(settings.selectedMode, .short)
        XCTAssertEqual(settings.selectedTheme, .wood)
        XCTAssertEqual(settings.afterRound, .keepPlaying)
    }

    // MARK: Onboarding detection

    func testFreshInstallNeedsOnboarding() {
        XCTAssertFalse(UserDefaultsSettingsStorage(defaults: defaults).hasCompletedOnboarding)
    }

    func testFreshInstallStillNeedsOnboardingAfterProfilesAreCreated() {
        let settings = UserDefaultsSettingsStorage(defaults: defaults)
        _ = UserDefaultsProfileStorage(defaults: defaults)
        XCTAssertFalse(settings.hasCompletedOnboarding)
        XCTAssertFalse(
            UserDefaultsSettingsStorage(defaults: defaults).hasCompletedOnboarding,
            "Quitting mid-onboarding doesn't skip it next launch")
    }

    func testFreshInstallNeedsOnboardingWhateverTheCreationOrder() {
        _ = UserDefaultsProfileStorage(defaults: defaults)
        XCTAssertFalse(UserDefaultsSettingsStorage(defaults: defaults).hasCompletedOnboarding)
    }

    func testExistingInstallsSkipOnboarding() {
        for key in ["pawpaw.profiles", "pawpaw.stats", "pawpaw.highScore"] {
            let defaults = makeTestDefaults()
            defaults.set(Data(), forKey: key)
            XCTAssertTrue(
                UserDefaultsSettingsStorage(defaults: defaults).hasCompletedOnboarding, key)
        }
    }

    /// "Devices that already have cats, scores or stats skip onboarding", whichever mode the
    /// old score is for.
    func testInstallsWithOnlyOtherModeScoresSkipOnboarding() {
        for key in ["pawpaw.highScore.short", "pawpaw.highScore.long"] {
            let defaults = makeTestDefaults()
            defaults.set(30, forKey: key)
            XCTAssertTrue(
                UserDefaultsSettingsStorage(defaults: defaults).hasCompletedOnboarding, key)
        }
    }

    func testLegacyScoreKeys() {
        XCTAssertEqual(StorageKeys.legacyHighScore(for: .standard), "pawpaw.highScore")
        XCTAssertEqual(StorageKeys.legacyHighScore(for: .short), "pawpaw.highScore.short")
        XCTAssertEqual(StorageKeys.legacyHighScore(for: .long), "pawpaw.highScore.long")
        XCTAssertNil(StorageKeys.legacyHighScore(for: .relaxed))
    }

    func testKeysKeepTheirStoredFormat() {
        let id = UUID()
        XCTAssertEqual(StorageKeys.profiles, "pawpaw.profiles")
        XCTAssertEqual(StorageKeys.legacyStats, "pawpaw.stats")
        XCTAssertEqual(StorageKeys.stats(for: id), "pawpaw.\(id.uuidString).stats")
        XCTAssertEqual(
            StorageKeys.highScore(for: .short, profileID: id),
            "pawpaw.\(id.uuidString).highScore.short")
    }

    // MARK: Profile deletion

    func testDeleteResetsScoresAndStatsThroughInjectedStorages() throws {
        var scores: [UUID: MockScoreStorage] = [:]
        var stats: [UUID: MockStatsStorage] = [:]
        let storage = UserDefaultsProfileStorage(
            defaults: defaults,
            makeScoreStorage: { id in
                let made = scores[id] ?? MockScoreStorage()
                scores[id] = made
                return made
            },
            makeStatsStorage: { id in
                let made = stats[id] ?? MockStatsStorage()
                stats[id] = made
                return made
            })
        let gone = try XCTUnwrap(storage.add(name: "Mochi", face: .gray)).id
        let keep = storage.activeProfile.id

        storage.delete(gone)

        XCTAssertEqual(scores[gone]?.resetCount, 1)
        XCTAssertEqual(stats[gone]?.resetCount, 1)
        XCTAssertEqual(scores[keep]?.resetCount ?? 0, 0, "The other cat's storages aren't touched")
        XCTAssertEqual(stats[keep]?.resetCount ?? 0, 0)
    }

    func testRejectedDeleteDoesNotResetAnything() {
        var scores: [UUID: MockScoreStorage] = [:]
        let storage = UserDefaultsProfileStorage(
            defaults: defaults,
            makeScoreStorage: { id in
                let made = scores[id] ?? MockScoreStorage()
                scores[id] = made
                return made
            })

        storage.delete(storage.activeProfile.id)

        XCTAssertEqual(scores.values.map(\.resetCount).reduce(0, +), 0, "The last cat stays")
    }

    func testUnrelatedKeysDontSkipOnboarding() {
        defaults.set(30, forKey: "pawpaw.highScore.relaxed")
        defaults.set(true, forKey: "pawpaw.hasLearnedHoldToExit")
        XCTAssertFalse(UserDefaultsSettingsStorage(defaults: defaults).hasCompletedOnboarding)
    }
}
