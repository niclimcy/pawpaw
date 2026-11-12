//
//  ThemePickerAccessibilityTests.swift
//  pawpawTests
//

import UIKit
import XCTest

@testable import pawpaw

@MainActor
final class ThemePickerAccessibilityTests: XCTestCase {
    private func tile(_ theme: PlayfieldTheme, in picker: ThemePickerView) throws -> ThemeTile {
        try XCTUnwrap(
            picker.firstSubview(identifier: "theme_\(theme.rawValue)") as? ThemeTile)
    }

    private func checkmark(in tile: ThemeTile) throws -> UIView {
        try XCTUnwrap(tile.firstSubview(identifier: "themeCheckmark"))
    }

    func testSelectionShowsCheckmarkOnlyOnSelectedTile() throws {
        let picker = ThemePickerView()
        picker.select(.pond)

        for theme in PlayfieldTheme.allCases {
            let themeTile = try tile(theme, in: picker)
            let isSelected = theme == .pond
            XCTAssertEqual(try checkmark(in: themeTile).isHidden, !isSelected, "\(theme)")
            XCTAssertEqual(
                themeTile.accessibilityTraits.contains(.selected), isSelected, "\(theme)")
        }
    }

    func testCheckmarkIsNotAnAccessibilityElement() throws {
        let picker = ThemePickerView()
        picker.select(.wood)
        XCTAssertFalse(try checkmark(in: tile(.wood, in: picker)).isAccessibilityElement)
    }

    func testSelectingAnotherThemeMovesCheckmark() throws {
        let picker = ThemePickerView()
        picker.select(.grass)
        picker.select(.snow)

        XCTAssertTrue(try checkmark(in: tile(.grass, in: picker)).isHidden)
        XCTAssertFalse(try checkmark(in: tile(.snow, in: picker)).isHidden)
        XCTAssertFalse(try tile(.grass, in: picker).accessibilityTraits.contains(.selected))
        XCTAssertTrue(try tile(.snow, in: picker).accessibilityTraits.contains(.selected))
    }
}

extension UIView {
    fileprivate func firstSubview(identifier: String) -> UIView? {
        for subview in subviews {
            if subview.accessibilityIdentifier == identifier { return subview }
            if let match = subview.firstSubview(identifier: identifier) { return match }
        }
        return nil
    }
}
