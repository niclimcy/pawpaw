//
//  ProfileStorageTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

/// First launch, legacy migration and repair.
@MainActor
final class ProfileStorageTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        defaults = makeTestDefaults()
    }

    func testCreatesOneDefaultCat() {
        let storage = UserDefaultsProfileStorage(defaults: defaults)
        XCTAssertEqual(storage.profiles.count, 1)
        XCTAssertEqual(storage.profiles[0].name, CatProfile.defaultName)
        XCTAssertEqual(storage.activeProfile, storage.profiles[0])
    }

    func testDefaultCatIsStableAcrossLaunches() {
        let first = UserDefaultsProfileStorage(defaults: defaults).activeProfile
        let second = UserDefaultsProfileStorage(defaults: defaults).activeProfile
        XCTAssertEqual(first, second)
    }

    func testMigratesLegacyScoresAndStatsToFirstCat() throws {
        defaults.set(50, forKey: "pawpaw.highScore")
        defaults.set(20, forKey: "pawpaw.highScore.short")
        defaults.set(90, forKey: "pawpaw.highScore.long")
        var legacy = PlayStats()
        legacy.record(catches: [.mouse: 4])
        defaults.set(try JSONEncoder().encode(legacy), forKey: "pawpaw.stats")

        let id = UserDefaultsProfileStorage(defaults: defaults).activeProfile.id
        let scores = UserDefaultsScoreStorage(defaults: defaults, profileID: id)

        XCTAssertEqual(scores.highScore(for: .standard), 50)
        XCTAssertEqual(scores.highScore(for: .short), 20)
        XCTAssertEqual(scores.highScore(for: .long), 90)
        XCTAssertEqual(scores.highScore(for: .relaxed), 0)
        XCTAssertEqual(UserDefaultsStatsStorage(defaults: defaults, profileID: id).stats, legacy)
        XCTAssertEqual(defaults.integer(forKey: "pawpaw.highScore"), 50, "Legacy keys stay")
    }

    func testMigrationRunsOnlyOnce() {
        let id = UserDefaultsProfileStorage(defaults: defaults).activeProfile.id
        defaults.set(999, forKey: "pawpaw.highScore")
        _ = UserDefaultsProfileStorage(defaults: defaults)
        XCTAssertEqual(
            UserDefaultsScoreStorage(defaults: defaults, profileID: id).highScore(for: .standard), 0
        )
    }

    func testRepairsCorruptProfilesWithFixedID() {
        defaults.set(Data("not json".utf8), forKey: "pawpaw.profiles")
        let storage = UserDefaultsProfileStorage(defaults: defaults)
        XCTAssertEqual(storage.profiles.map(\.id), [UserDefaultsProfileStorage.fallbackID])
        XCTAssertEqual(storage.activeProfile.id, UserDefaultsProfileStorage.fallbackID)
        XCTAssertEqual(
            UserDefaultsProfileStorage(defaults: defaults).activeProfile.id,
            UserDefaultsProfileStorage.fallbackID, "Each read doesn't mint a new ID")
    }

    func testRepairsEmptyList() throws {
        defaults.set(try JSONEncoder().encode([CatProfile]()), forKey: "pawpaw.profiles")
        let storage = UserDefaultsProfileStorage(defaults: defaults)
        XCTAssertEqual(storage.profiles.map(\.id), [UserDefaultsProfileStorage.fallbackID])
    }

    func testProfilesNeverEmptyEvenIfDataBreaksAfterInit() {
        let storage = UserDefaultsProfileStorage(defaults: defaults)
        defaults.set(Data("broken".utf8), forKey: "pawpaw.profiles")
        XCTAssertEqual(storage.profiles.map(\.id), [UserDefaultsProfileStorage.fallbackID])
        XCTAssertEqual(storage.activeProfile.id, UserDefaultsProfileStorage.fallbackID)
    }

    func testActiveFallsBackToFirstCatWhenActiveIDIsStale() {
        let storage = UserDefaultsProfileStorage(defaults: defaults)
        defaults.set(UUID().uuidString, forKey: "pawpaw.activeProfile")
        XCTAssertEqual(storage.activeProfile, storage.profiles[0])
    }
}
