//
//  ProfileEditorAccessibilityTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class ProfileEditorAccessibilityTests: XCTestCase {
    private func view(_ identifier: String, in root: UIView) -> UIView? {
        if root.accessibilityIdentifier == identifier { return root }
        for subview in root.subviews {
            if let match = view(identifier, in: subview) { return match }
        }
        return nil
    }

    func testDeleteButtonHasACustomActionThatDeletes() throws {
        let editor = ProfileEditorView()
        var deleted = false
        editor.onDelete = { deleted = true }

        let button = try XCTUnwrap(view("deleteCatButton", in: editor))
        let action = try XCTUnwrap(button.accessibilityCustomActions?.first)
        XCTAssertEqual(action.name, "Delete cat")

        XCTAssertEqual(action.actionHandler?(action), true)
        XCTAssertTrue(deleted)
    }

    func testCrittersSayOnOrOffWithoutTheSelectedTrait() throws {
        let editor = ProfileEditorView()
        editor.showCritters(disabledKinds: [.laser])

        for kind in TargetKind.allCases {
            let button = try XCTUnwrap(view("critter_\(kind.rawValue)", in: editor))
            XCTAssertEqual(button.accessibilityValue, kind == .laser ? "Off" : "On", "\(kind)")
            XCTAssertFalse(button.accessibilityTraits.contains(.selected), "\(kind)")
            XCTAssertTrue(button.accessibilityTraits.contains(.button), "\(kind)")
        }
    }
}
