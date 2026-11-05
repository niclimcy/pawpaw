//
//  PlayfieldGeometryTests.swift
//  pawpawTests
//

import CoreGraphics
import XCTest

@testable import pawpaw

@MainActor
final class PlayfieldGeometryTests: XCTestCase {
    private let geometry = PlayfieldGeometry(
        size: CGSize(width: 1000, height: 800), topInset: 100, tuning: .standard)

    func testFieldExcludesTopInset() {
        XCTAssertEqual(geometry.field, CGRect(x: 0, y: 0, width: 1000, height: 700))
        XCTAssertEqual(geometry.bounds, CGRect(x: 0, y: 0, width: 1000, height: 800))
    }

    func testFieldNeverNegative() {
        let tiny = PlayfieldGeometry(size: CGSize(width: 10, height: 10), topInset: 50)
        XCTAssertEqual(tiny.field.height, 0)
    }

    func testNormalizedTopLeftMapsBelowHUD() {
        let inset = geometry.targetSize / 2 + 8
        let topLeft = geometry.point(for: CGPoint(x: 0, y: 0))
        XCTAssertEqual(topLeft.x, inset, accuracy: 1e-9)
        XCTAssertEqual(topLeft.y, geometry.field.maxY - inset, accuracy: 1e-9)
        let bottomRight = geometry.point(for: CGPoint(x: 1, y: 1))
        XCTAssertEqual(bottomRight.x, 1000 - inset, accuracy: 1e-9)
        XCTAssertEqual(bottomRight.y, inset, accuracy: 1e-9)
    }

    func testNormalizedIsInverseOfPoint() {
        for _ in 0..<200 {
            let original = CGPoint(x: .random(in: -0.5...1.5), y: .random(in: -0.5...1.5))
            let roundTrip = geometry.normalized(for: geometry.point(for: original))
            XCTAssertEqual(roundTrip.x, original.x, accuracy: 1e-9, "\(original)")
            XCTAssertEqual(roundTrip.y, original.y, accuracy: 1e-9, "\(original)")
        }
    }

    func testOffscreenPointPushesEdgesPastScreen() {
        let margin = geometry.targetSize * 0.75
        XCTAssertEqual(geometry.offscreenPoint(for: CGPoint(x: 0, y: 0.5)).x, -margin)
        XCTAssertEqual(geometry.offscreenPoint(for: CGPoint(x: 1, y: 0.5)).x, 1000 + margin)
        XCTAssertEqual(
            geometry.offscreenPoint(for: CGPoint(x: 0.5, y: 0)).y, 800 + margin,
            "Top edge clears the HUD strip too")
        XCTAssertEqual(geometry.offscreenPoint(for: CGPoint(x: 0.5, y: 1)).y, -margin)
        let inner = CGPoint(x: 0.5, y: 0.5)
        XCTAssertEqual(geometry.offscreenPoint(for: inner), geometry.point(for: inner))
    }

    func testHideEdgePointPicksNearestEdge() {
        let margin = geometry.targetSize * 0.75
        XCTAssertEqual(geometry.hideEdgePoint(from: CGPoint(x: 10, y: 400)).x, -margin)
        XCTAssertEqual(geometry.hideEdgePoint(from: CGPoint(x: 990, y: 400)).x, 1000 + margin)
        XCTAssertEqual(geometry.hideEdgePoint(from: CGPoint(x: 500, y: 10)).y, -margin)
        XCTAssertEqual(geometry.hideEdgePoint(from: CGPoint(x: 500, y: 690)).y, 800 + margin)
    }

    func testPeekPointIsOnSpotRim() {
        let center = CGPoint(x: 300, y: 300)
        for _ in 0..<50 {
            let peek = geometry.peekPoint(from: center)
            XCTAssertEqual(
                hypot(peek.x - center.x, peek.y - center.y), geometry.hidingSpotSize / 2,
                accuracy: 1e-6)
        }
    }

    func testNodPointMovesTenPointsForward() {
        let nod = geometry.nodPoint(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 100, y: 0))
        XCTAssertEqual(nod, CGPoint(x: 110, y: 0))
        let stationary = geometry.nodPoint(from: CGPoint(x: 5, y: 5), to: CGPoint(x: 5, y: 5))
        XCTAssertEqual(stationary, CGPoint(x: 5, y: 5), "No movement, no NaN")
    }

    func testPanIsNeverFullyOneSided() {
        XCTAssertEqual(geometry.pan(atX: 0), -0.8, accuracy: 1e-6)
        XCTAssertEqual(geometry.pan(atX: 500), 0, accuracy: 1e-6)
        XCTAssertEqual(geometry.pan(atX: 1000), 0.8, accuracy: 1e-6)
        XCTAssertEqual(geometry.pan(atX: -500), -0.8, accuracy: 1e-6)
        XCTAssertEqual(geometry.pan(atX: 5000), 0.8, accuracy: 1e-6)
    }

    func testPanWithZeroWidthIsCentered() {
        XCTAssertEqual(PlayfieldGeometry(size: .zero).pan(atX: 10), 0)
    }

    func testLureCoverFrameAndSpots() {
        let card = CGRect(x: 300, y: 250, width: 400, height: 300)
        let cover = geometry.lureCover(for: card)

        let corner = geometry.normalized(for: CGPoint(x: card.minX, y: card.maxY))
        XCTAssertEqual(cover.frame.minX, corner.x, accuracy: 1e-9)
        XCTAssertEqual(cover.frame.minY, corner.y, accuracy: 1e-9)
        XCTAssertEqual(cover.spots.count, 6, "A centred card has every peek point on the field")
        for spot in cover.spots {
            XCTAssertTrue((0...1).contains(spot.peek.x) && (0...1).contains(spot.peek.y))
            XCTAssertTrue(cover.frame.contains(spot.hide), "Hide point is under the card")
            XCTAssertFalse(
                cover.frame.insetBy(dx: 0.001, dy: 0.001).contains(spot.peek),
                "Peek point is at or past the card's edge")
        }
    }

    func testLureCoverDropsPeeksOffTheField() {
        // A card filling the whole field has no edge to peek past.
        let cover = geometry.lureCover(for: geometry.field)
        XCTAssertTrue(cover.spots.isEmpty)
    }
}
