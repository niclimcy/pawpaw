//
//  StatsAccessibilityTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class StatsAccessibilityTests: XCTestCase {
    func testResetButtonOffersResetAsCustomAction() throws {
        // No presenter, so nothing reads or writes stored stats.
        let controller = StatsViewController()
        controller.loadViewIfNeeded()

        let button = try XCTUnwrap(
            Self.findView(identifier: "statsResetButton", in: controller.view) as? UIButton)
        let names = button.accessibilityCustomActions?.map(\.name) ?? []
        XCTAssertEqual(names, ["Reset stats"])
    }

    private static func findView(identifier: String, in root: UIView) -> UIView? {
        if root.accessibilityIdentifier == identifier { return root }
        for subview in root.subviews {
            if let match = findView(identifier: identifier, in: subview) { return match }
        }
        return nil
    }
}
