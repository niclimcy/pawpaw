//
//  AdaptiveLayoutTests.swift
//  pawpawTests
//

import UIKit
import XCTest

@testable import pawpaw

@MainActor
final class AdaptiveLayoutTests: XCTestCase {
    private func traits(
        _ horizontal: UIUserInterfaceSizeClass, _ vertical: UIUserInterfaceSizeClass
    ) -> UITraitCollection {
        UITraitCollection { traits in
            traits.horizontalSizeClass = horizontal
            traits.verticalSizeClass = vertical
        }
    }

    func testRoomBothWaysOnlyWhenRegularBothWays() {
        XCTAssertTrue(UIInterfaceOrientationMask.hasRoomBothWays(traits(.regular, .regular)))
        // iPhone Pro Max in landscape.
        XCTAssertFalse(UIInterfaceOrientationMask.hasRoomBothWays(traits(.regular, .compact)))
        // iPhone in portrait, or iPad in narrow Split View.
        XCTAssertFalse(UIInterfaceOrientationMask.hasRoomBothWays(traits(.compact, .regular)))
        XCTAssertFalse(UIInterfaceOrientationMask.hasRoomBothWays(traits(.compact, .compact)))
    }

    func testCountdownTurnsOnlyWhereTheGameLocksLandscape() {
        XCTAssertEqual(
            OnboardingCountdownView.pose(
                locksLandscape: true, size: CGSize(width: 390, height: 844)),
            .turnsToLandscape)
        XCTAssertEqual(
            OnboardingCountdownView.pose(
                locksLandscape: true, size: CGSize(width: 844, height: 390)),
            .landscape)
    }

    /// iPad and iPhone Duo's inner display follow the device.
    func testCountdownFollowsOrientationWhenNotLocked() {
        XCTAssertEqual(
            OnboardingCountdownView.pose(
                locksLandscape: false, size: CGSize(width: 820, height: 1180)),
            .portrait)
        XCTAssertEqual(
            OnboardingCountdownView.pose(
                locksLandscape: false, size: CGSize(width: 1180, height: 820)),
            .landscape)
    }

    func testSideBySideOnlyWhenWideWithRegularWidth() {
        // iPhone Duo's inner display, 669 × 951pt.
        XCTAssertTrue(
            AdaptiveLayout.isWide(
                size: CGSize(width: 951, height: 669), horizontalSizeClass: .regular))
        XCTAssertFalse(
            AdaptiveLayout.isWide(
                size: CGSize(width: 669, height: 951), horizontalSizeClass: .regular))
        // Folded iPhone Duo's outer display in landscape, while the size class is still regular.
        XCTAssertFalse(
            AdaptiveLayout.isWide(
                size: CGSize(width: 678, height: 466), horizontalSizeClass: .regular))
        // A compact-width window that happens to be wide, like iPad Slide Over turned sideways.
        XCTAssertFalse(
            AdaptiveLayout.isWide(
                size: CGSize(width: 500, height: 400), horizontalSizeClass: .compact))
    }

    func testTopInsetCorrectsToStatusBarAlongTop() {
        let topBar = CGRect(x: 0, y: 0, width: 667, height: 20)
        XCTAssertEqual(
            OrientationNavigationController.topInsetCorrection(
                reportedTop: 0, statusBarFrame: topBar), 20)
        XCTAssertEqual(
            OrientationNavigationController.topInsetCorrection(
                reportedTop: 20, statusBarFrame: .zero), -20)
    }

    func testStatsGivesBackHalfOfAnUnmatchedBottomInset() {
        // Folded iPhone Duo: home indicator below, status bar down the side.
        XCTAssertEqual(StatsViewController.bottomInsetBalance(top: 0, bottom: 34), -17)
        XCTAssertEqual(StatsViewController.bottomInsetBalance(top: 59, bottom: 34), 0)
    }

    func testTopInsetIsNotCorrectedForSideStatusBar() {
        let sideBar = CGRect(x: 560, y: 0, width: 40, height: 840)
        XCTAssertEqual(
            OrientationNavigationController.topInsetCorrection(
                reportedTop: 0, statusBarFrame: sideBar), 0)
    }
}
