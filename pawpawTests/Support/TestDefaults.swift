//
//  TestDefaults.swift
//  pawpawTests
//

import Foundation
import XCTest

extension XCTestCase {
    /// A throwaway `UserDefaults` suite, removed when the test ends, so tests never touch `.standard`.
    func makeTestDefaults() -> UserDefaults {
        let suiteName = "pawpawTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Couldn't create the UserDefaults suite \(suiteName)")
        }
        addTeardownBlock {
            UserDefaults().removePersistentDomain(forName: suiteName)
        }
        return defaults
    }
}

/// A Gregorian UTC calendar, so day maths doesn't depend on the simulator's time zone or DST.
func utcCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}

func utcDate(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
    utcCalendar().date(
        from: DateComponents(year: year, month: month, day: day, hour: hour))!
}
