//
//  DifficultyTunerTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class DifficultyTunerTests: XCTestCase {
    func testStartsAtNormalPace() {
        XCTAssertEqual(DifficultyTuner().pace, 1)
    }

    func testStepsInEachDirection() {
        var tuner = DifficultyTuner()
        tuner.recordCatch()
        XCTAssertEqual(tuner.pace, 1.05, accuracy: 1e-9)
        tuner.recordEscape()
        XCTAssertEqual(tuner.pace, 1.0, accuracy: 1e-9)
        tuner.recordMiss()
        XCTAssertEqual(tuner.pace, 0.98, accuracy: 1e-9)
    }

    func testMissesCostLessThanEscapes() {
        XCTAssertLessThan(DifficultyTuner.missStep, DifficultyTuner.escapeStep)
    }

    func testClampsAtUpperBound() {
        var tuner = DifficultyTuner()
        for _ in 0..<100 { tuner.recordCatch() }
        XCTAssertEqual(tuner.pace, DifficultyTuner.paceRange.upperBound, accuracy: 1e-9)
    }

    func testClampsAtLowerBound() {
        var tuner = DifficultyTuner()
        for _ in 0..<100 { tuner.recordEscape() }
        XCTAssertEqual(tuner.pace, DifficultyTuner.paceRange.lowerBound, accuracy: 1e-9)
        for _ in 0..<100 { tuner.recordMiss() }
        XCTAssertEqual(tuner.pace, DifficultyTuner.paceRange.lowerBound, accuracy: 1e-9)
    }

    func testRecoversFromBoundImmediately() {
        var tuner = DifficultyTuner()
        for _ in 0..<100 { tuner.recordCatch() }
        tuner.recordEscape()
        XCTAssertEqual(
            tuner.pace, DifficultyTuner.paceRange.upperBound - DifficultyTuner.escapeStep,
            accuracy: 1e-9)
    }

    func testReset() {
        var tuner = DifficultyTuner()
        tuner.recordCatch()
        tuner.reset()
        XCTAssertEqual(tuner, DifficultyTuner())
    }

    func testFasterPaceShortensLifetime() {
        var tuner = DifficultyTuner()
        XCTAssertEqual(tuner.lifetime(for: 6), 6, accuracy: 1e-9)
        for _ in 0..<100 { tuner.recordCatch() }
        XCTAssertEqual(tuner.lifetime(for: 6.5), 5, accuracy: 1e-9)
    }
}
