//
//  ThemeContrastTests.swift
//  pawpawTests
//

import UIKit
import XCTest

@testable import pawpaw

/// WCAG 2 contrast checks behind the Sufficient Contrast and Larger Text App Store labels.
@MainActor
final class ThemeContrastTests: XCTestCase {
    private func components(_ color: UIColor) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    /// `color` composited over the opaque `background`.
    private func flattened(_ color: UIColor, over background: UIColor) -> UIColor {
        let fg = components(color)
        let bg = components(background)
        return UIColor(
            red: fg.r * fg.a + bg.r * (1 - fg.a),
            green: fg.g * fg.a + bg.g * (1 - fg.a),
            blue: fg.b * fg.a + bg.b * (1 - fg.a),
            alpha: 1)
    }

    private func luminance(_ color: UIColor) -> CGFloat {
        func linear(_ c: CGFloat) -> CGFloat {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let c = components(color)
        return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b)
    }

    private func contrast(_ foreground: UIColor, on background: UIColor) -> CGFloat {
        let a = luminance(flattened(foreground, over: background))
        let b = luminance(background)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    func testTextOnAccentMeetsBodyTextContrast() {
        XCTAssertGreaterThanOrEqual(contrast(Theme.onAccent, on: Theme.accent), 4.5)
    }

    func testFaintestTextShadeMeetsBodyTextContrast() {
        for background in [Theme.panel, Theme.background] {
            XCTAssertGreaterThanOrEqual(contrast(Theme.sectionText, on: background), 4.5)
        }
    }

    func testAccentAndGoldStandOutFromCards() {
        XCTAssertGreaterThanOrEqual(contrast(Theme.accent, on: Theme.panel), 4.5)
        XCTAssertGreaterThanOrEqual(contrast(Theme.gold, on: Theme.panel), 4.5)
    }

    func testTextCanGrowToTwiceItsSize() {
        XCTAssertGreaterThanOrEqual(Theme.maxTextScale, 2)
    }
}
