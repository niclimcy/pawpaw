//
//  CatProfileTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class CatProfileTests: XCTestCase {
    // MARK: Names

    func testCleanedTrimsWhitespaceAndNewlines() {
        XCTAssertEqual(CatProfile.cleaned("  Mochi \n"), "Mochi")
    }

    func testCleanedRejectsBlankNames() {
        XCTAssertNil(CatProfile.cleaned(""))
        XCTAssertNil(CatProfile.cleaned("   \n\t"))
    }

    func testCleanedCapsLength() {
        let long = String(repeating: "a", count: 30)
        XCTAssertEqual(CatProfile.cleaned(long)?.count, CatProfile.maxNameLength)
        let exact = String(repeating: "b", count: CatProfile.maxNameLength)
        XCTAssertEqual(CatProfile.cleaned(exact), exact)
    }

    func testCleanedTrimsBeforeCapping() {
        let padded = "   " + String(repeating: "c", count: CatProfile.maxNameLength)
        XCTAssertEqual(CatProfile.cleaned(padded), String(repeating: "c", count: 20))
    }

    func testInitFallsBackToDefaultName() {
        XCTAssertEqual(CatProfile(name: "  ").name, CatProfile.defaultName)
        XCTAssertEqual(CatProfile(name: " Luna ").name, "Luna")
    }

    func testInitDefaults() {
        let profile = CatProfile(name: "Luna")
        XCTAssertEqual(profile.face, .orange)
        XCTAssertTrue(profile.disabledKinds.isEmpty)
        XCTAssertEqual(profile.enabledKinds, TargetKind.allCases)
    }

    // MARK: Enabled kinds

    func testEnabledKindsKeepsCaseOrder() {
        let profile = CatProfile(name: "Luna", disabledKinds: [.bug, .laser])
        XCTAssertEqual(
            profile.enabledKinds, TargetKind.allCases.filter { $0 != .bug && $0 != .laser })
    }

    func testIsPlayableNeedsAnEveryThemeCritter() {
        XCTAssertTrue(CatProfile.isPlayable(disabledKinds: []))

        let onlyThemed = Set(TargetKind.allCases.filter { $0.exclusiveTheme == nil })
        XCTAssertFalse(
            CatProfile.isPlayable(disabledKinds: onlyThemed),
            "Only fish and lizard left can't play on wood or snow")
        XCTAssertFalse(CatProfile.isPlayable(disabledKinds: Set(TargetKind.allCases)))
    }

    func testIsPlayableWithASingleEveryThemeCritter() {
        let mouseOnly = Set(TargetKind.allCases.filter { $0 != .mouse })
        XCTAssertTrue(CatProfile.isPlayable(disabledKinds: mouseOnly))
    }

    // MARK: Codable

    func testCodableRoundTrip() throws {
        let profile = CatProfile(name: "Luna", face: .siamese, disabledKinds: [.fish, .bug])
        let decoded = try JSONDecoder().decode(
            CatProfile.self, from: JSONEncoder().encode(profile))
        XCTAssertEqual(decoded, profile)
    }

    func testEncodesDisabledKindsSorted() throws {
        let profile = CatProfile(name: "Luna", disabledKinds: [.mouse, .bird, .laser])
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(profile)) as? [String: Any])
        XCTAssertEqual(json["disabledKinds"] as? [String], ["bird", "laser", "mouse"])
    }

    func testDecodesLegacyProfileWithoutFaceOrKinds() throws {
        let id = UUID()
        let json = #"{"id":"\#(id.uuidString)","name":"Old Cat"}"#
        let profile = try JSONDecoder().decode(CatProfile.self, from: Data(json.utf8))
        XCTAssertEqual(profile.id, id)
        XCTAssertEqual(profile.name, "Old Cat")
        XCTAssertEqual(profile.face, .orange)
        XCTAssertTrue(profile.disabledKinds.isEmpty)
    }

    func testDecodesEmojiFaceAsOrange() throws {
        let json = #"{"id":"\#(UUID().uuidString)","name":"Old Cat","face":"🐱"}"#
        let profile = try JSONDecoder().decode(CatProfile.self, from: Data(json.utf8))
        XCTAssertEqual(profile.face, .orange)
    }

    func testDecodingSkipsUnknownKinds() throws {
        let json =
            #"{"id":"\#(UUID().uuidString)","name":"Cat","disabledKinds":["bug","dragon"]}"#
        let profile = try JSONDecoder().decode(CatProfile.self, from: Data(json.utf8))
        XCTAssertEqual(profile.disabledKinds, [.bug])
    }

    func testDecodingFailsWithoutID() {
        let json = #"{"name":"Cat"}"#
        XCTAssertThrowsError(try JSONDecoder().decode(CatProfile.self, from: Data(json.utf8)))
    }
}
