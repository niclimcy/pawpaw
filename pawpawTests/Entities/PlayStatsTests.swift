//
//  PlayStatsTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class PlayStatsTests: XCTestCase {
    private let calendar = utcCalendar()

    func testStartsEmpty() {
        let stats = PlayStats()
        XCTAssertEqual(stats.totalRounds, 0)
        XCTAssertEqual(stats.totalCatches, 0)
        XCTAssertNil(stats.favoriteKind)
        for kind in TargetKind.allCases { XCTAssertEqual(stats.catches(of: kind), 0) }
    }

    func testRecordCountsCatchesAndOneRound() {
        var stats = PlayStats()
        stats.record(
            catches: [.mouse: 2, .bug: 3], on: utcDate(2026, 5, 11), calendar: calendar)

        XCTAssertEqual(stats.totalRounds, 1)
        XCTAssertEqual(stats.totalCatches, 5)
        XCTAssertEqual(stats.catches(of: .mouse), 2)
        XCTAssertEqual(stats.catches(of: .bug), 3)
        XCTAssertEqual(stats.roundsByDay["2026-05-11"], 1)
    }

    func testLaterPartOfInterruptedRoundAddsCatchesButNoRound() {
        var stats = PlayStats()
        let day = utcDate(2026, 5, 11)
        stats.record(catches: [.mouse: 1], isNewRound: true, on: day, calendar: calendar)
        stats.record(catches: [.mouse: 2], isNewRound: false, on: day, calendar: calendar)

        XCTAssertEqual(stats.totalRounds, 1)
        XCTAssertEqual(stats.totalCatches, 3)
        XCTAssertEqual(stats.roundsByDay["2026-05-11"], 1)
    }

    func testFavoriteIsMostCaught() {
        var stats = PlayStats()
        stats.record(catches: [.bug: 1, .laser: 4, .fish: 2])
        XCTAssertEqual(stats.favoriteKind, .laser)
    }

    func testFavoriteTieGoesToEarliestCase() {
        var stats = PlayStats()
        // `.butterfly` comes before `.bird` in `TargetKind`.
        stats.record(catches: [.bird: 3, .butterfly: 3])
        XCTAssertEqual(stats.favoriteKind, .butterfly)
    }

    func testFavoriteIgnoresZeroCounts() {
        var stats = PlayStats()
        stats.record(catches: [.mouse: 0])
        XCTAssertNil(stats.favoriteKind)
    }

    func testDayKeyIsZeroPadded() {
        XCTAssertEqual(PlayStats.dayKey(for: utcDate(2026, 1, 5), calendar: calendar), "2026-01-05")
    }

    func testRecentRoundsAreOldestFirstEndingToday() {
        var stats = PlayStats()
        let today = utcDate(2026, 5, 11)
        stats.record(catches: [.mouse: 1], on: today, calendar: calendar)
        stats.record(catches: [.mouse: 1], on: today, calendar: calendar)
        stats.record(catches: [.mouse: 1], on: utcDate(2026, 5, 9), calendar: calendar)
        // Outside the window.
        stats.record(catches: [.mouse: 1], on: utcDate(2026, 5, 1), calendar: calendar)

        let days = stats.recentRounds(days: 7, endingOn: today, calendar: calendar)

        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(days.map(\.rounds), [0, 0, 0, 0, 1, 0, 2])
        XCTAssertEqual(PlayStats.dayKey(for: days[0].date, calendar: calendar), "2026-05-05")
        XCTAssertEqual(PlayStats.dayKey(for: days[6].date, calendar: calendar), "2026-05-11")
    }

    func testRecentRoundsCrossMonthAndYearBoundaries() {
        let days = PlayStats().recentRounds(
            days: 3, endingOn: utcDate(2026, 1, 1), calendar: calendar)
        XCTAssertEqual(
            days.map { PlayStats.dayKey(for: $0.date, calendar: calendar) },
            ["2025-12-30", "2025-12-31", "2026-01-01"])
    }

    func testRecentRoundsWithZeroDaysIsEmpty() {
        XCTAssertTrue(PlayStats().recentRounds(days: 0).isEmpty)
    }
}
