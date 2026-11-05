//
//  SeededGeneratorTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class SeededGeneratorTests: XCTestCase {
    func testSameSeedGivesSameSequence() {
        var first = SeededGenerator(seed: 42)
        var second = SeededGenerator(seed: 42)
        let a = (0..<20).map { _ in first.next() }
        let b = (0..<20).map { _ in second.next() }
        XCTAssertEqual(a, b)
    }

    func testDifferentSeedsDiffer() {
        var first = SeededGenerator(seed: 1)
        var second = SeededGenerator(seed: 2)
        XCTAssertNotEqual(first.next(), second.next())
    }

    /// Known SplitMix64 output, so a refactor can't silently change every drawn background.
    func testMatchesSplitMix64ReferenceValues() {
        var generator = SeededGenerator(seed: 0)
        XCTAssertEqual(generator.next(), 0xE220_A839_7B1D_CDAF)
        XCTAssertEqual(generator.next(), 0x6E78_9E6A_A1B9_65F4)
    }

    func testWorksWithStandardLibraryRandomAPIs() {
        var first = SeededGenerator(seed: 7)
        var second = SeededGenerator(seed: 7)
        let a = (0..<50).map { _ in Int.random(in: 0..<1000, using: &first) }
        let b = (0..<50).map { _ in Int.random(in: 0..<1000, using: &second) }
        XCTAssertEqual(a, b)
        XCTAssertGreaterThan(Set(a).count, 1)
    }
}
