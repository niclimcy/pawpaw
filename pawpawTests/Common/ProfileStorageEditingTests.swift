//
//  ProfileStorageEditingTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class ProfileStorageEditingTests: XCTestCase {
    private var defaults: UserDefaults!
    private var storage: UserDefaultsProfileStorage!

    override func setUp() async throws {
        try await super.setUp()
        defaults = makeTestDefaults()
        storage = UserDefaultsProfileStorage(defaults: defaults)
    }

    func testAddKeepsInsertionOrderAndCleansName() throws {
        let added = try XCTUnwrap(storage.add(name: "  Mochi  ", face: .calico))
        XCTAssertEqual(added.name, "Mochi")
        XCTAssertEqual(storage.profiles.last, added)
        XCTAssertEqual(storage.profiles.count, 2)
        XCTAssertNotEqual(storage.activeProfile.id, added.id, "Adding doesn't switch cats")
    }

    func testAddRejectsBlankName() {
        XCTAssertNil(storage.add(name: "   ", face: .gray))
        XCTAssertEqual(storage.profiles.count, 1)
    }

    func testUpdateRenamesAndBlankNameKeepsOld() {
        let id = storage.activeProfile.id
        storage.update(id, name: "Luna", face: .black)
        XCTAssertEqual(storage.activeProfile.name, "Luna")
        XCTAssertEqual(storage.activeProfile.face, .black)

        storage.update(id, name: "  ", face: .white)
        XCTAssertEqual(storage.activeProfile.name, "Luna")
        XCTAssertEqual(storage.activeProfile.face, .white)
    }

    func testUpdateLeavesOtherCatsAlone() throws {
        let other = try XCTUnwrap(storage.add(name: "Mochi", face: .gray))
        storage.update(storage.activeProfile.id, name: "Luna", face: .black)
        XCTAssertEqual(storage.profiles.last, other)
    }

    func testSetActiveIgnoresUnknownID() throws {
        let second = try XCTUnwrap(storage.add(name: "Mochi", face: .gray))
        storage.setActive(second.id)
        XCTAssertEqual(storage.activeProfile.id, second.id)
        storage.setActive(UUID())
        XCTAssertEqual(storage.activeProfile.id, second.id)
    }

    func testSetDisabledKindsIgnoresUnplayableSets() {
        let id = storage.activeProfile.id
        storage.setDisabledKinds([.bug], for: id)
        XCTAssertEqual(storage.activeProfile.disabledKinds, [.bug])

        storage.setDisabledKinds(Set(TargetKind.allCases), for: id)
        XCTAssertEqual(storage.activeProfile.disabledKinds, [.bug])
    }

    func testLastCatCantBeDeleted() {
        storage.delete(storage.activeProfile.id)
        XCTAssertEqual(storage.profiles.count, 1)
    }

    func testDeletingActiveCatActivatesFirstRemaining() throws {
        let first = storage.activeProfile
        let second = try XCTUnwrap(storage.add(name: "Mochi", face: .gray))
        storage.setActive(second.id)
        storage.delete(second.id)
        XCTAssertEqual(storage.profiles, [first])
        XCTAssertEqual(storage.activeProfile, first)
    }

    func testDeleteRemovesOnlyThatCatsScoresAndStats() throws {
        let keep = storage.activeProfile.id
        let gone = try XCTUnwrap(storage.add(name: "Mochi", face: .gray)).id
        for id in [keep, gone] {
            UserDefaultsScoreStorage(defaults: defaults, profileID: id).saveHighScore(
                70, for: .short)
            UserDefaultsStatsStorage(defaults: defaults, profileID: id)
                .record(catches: [.bug: 1], isNewRound: true)
        }

        storage.delete(gone)

        func score(_ id: UUID) -> Int {
            UserDefaultsScoreStorage(defaults: defaults, profileID: id).highScore(for: .short)
        }
        func stats(_ id: UUID) -> PlayStats {
            UserDefaultsStatsStorage(defaults: defaults, profileID: id).stats
        }
        XCTAssertEqual(score(gone), 0)
        XCTAssertEqual(stats(gone), PlayStats())
        XCTAssertEqual(score(keep), 70)
        XCTAssertEqual(stats(keep).totalCatches, 1)
    }

    func testDeleteUnknownIDDoesNothing() throws {
        try XCTUnwrap(storage.add(name: "Mochi", face: .gray))
        storage.delete(UUID())
        XCTAssertEqual(storage.profiles.count, 2)
    }
}
