//
//  CritterNodeMotionTests.swift
//  pawpawTests
//

import SpriteKit
import XCTest

@testable import pawpaw

/// Plays critters in a live scene, as a plan's actions only run while SpriteKit renders.
@MainActor
final class CritterNodeMotionTests: XCTestCase {
    private var view: SKView!
    private let geometry = PlayfieldGeometry(
        size: CGSize(width: 1000, height: 800), topInset: 100, tuning: .standard)

    override func setUp() async throws {
        let window = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?
                .windows.first)
        view = SKView(frame: CGRect(x: 0, y: 0, width: 1000, height: 800))
        window.addSubview(view)
        view.presentScene(SKScene(size: view.bounds.size))
    }

    override func tearDown() async throws {
        view.removeFromSuperview()
        view = nil
    }

    /// Plays `kind` heading straight up the screen, so its hit box is unrotated, and samples
    /// `measure` every 20 ms for `seconds`.
    private func samples(
        of kind: TargetKind, seconds: TimeInterval, _ measure: (CritterNode) -> CGFloat
    ) async throws -> [CGFloat] {
        let target = GameTarget(
            id: UUID(), kind: kind, start: CGPoint(x: 0.5, y: 0.7),
            legs: [
                PathLeg(
                    destination: CGPoint(x: 0.5, y: 0.3), travel: 3, pause: 0, hides: false)
            ])
        let plan = try XCTUnwrap(CritterActions.plan(for: target, in: geometry))
        let artwork = try XCTUnwrap(
            PlayfieldTextures.critter(kind, variant: .standard, size: geometry.targetSize))
        let critter = CritterNode()
        view.scene?.addChild(critter)
        critter.play(
            plan, artwork: artwork, caughtArtwork: nil, layer: 0, canTakeCover: false,
            spawnOrder: 0, completion: {})
        let start = critter.position
        var values: [CGFloat] = []
        for _ in 0..<Int(seconds / 0.02) {
            try await Task.sleep(nanoseconds: 20_000_000)
            values.append(measure(critter))
        }
        XCTAssertNotEqual(critter.position, start, "the scene isn't running")
        return values
    }

    private func spread(_ values: [CGFloat]) -> CGFloat {
        (values.max() ?? 0) - (values.min() ?? 0)
    }

    /// Synchronous, so `run(_:)` is the plain overload rather than the one that awaits the action.
    private func run(_ actions: [SKAction], on node: SKNode) {
        for action in actions { node.run(action) }
    }

    /// Why `Timeline.actionIfAny` exists. If SpriteKit changes, this fails and the guard can go.
    func testAnEmptySequenceStopsActionsRunAfterIt() async throws {
        let node = SKNode()
        view.scene?.addChild(node)
        run([.sequence([]), .repeatForever(.rotate(byAngle: 1, duration: 1))], on: node)
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertFalse(node.hasActions())
        XCTAssertEqual(node.zRotation, 0)
    }

    func testButterflyFlapsItsWings() async throws {
        let widths = try await samples(of: .butterfly, seconds: 0.6) { $0.hitFrame.width }
        XCTAssertGreaterThan(spread(widths), geometry.targetSize * 0.3, "\(widths)")
    }

    func testLaserDotPulses() async throws {
        let widths = try await samples(of: .laser, seconds: 0.8) { $0.hitFrame.width }
        XCTAssertGreaterThan(spread(widths), geometry.targetSize * 0.05, "\(widths)")
    }

    func testFishTurnsOntoANewLegThenGlides() async throws {
        let target = GameTarget(
            id: UUID(), kind: .fish, start: CGPoint(x: 0.5, y: 0.7),
            legs: [
                PathLeg(destination: CGPoint(x: 0.5, y: 0.5), travel: 0.3, pause: 0, hides: false),
                PathLeg(destination: CGPoint(x: 0.7, y: 0.3), travel: 2, pause: 0, hides: false),
            ])
        let plan = try XCTUnwrap(CritterActions.plan(for: target, in: geometry))
        let artwork = try XCTUnwrap(
            PlayfieldTextures.critter(.fish, variant: .standard, size: geometry.targetSize))
        let critter = CritterNode()
        view.scene?.addChild(critter)
        critter.play(
            plan, artwork: artwork, caughtArtwork: nil, layer: 0, canTakeCover: false,
            spawnOrder: 0, completion: {})
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let heading = try XCTUnwrap(critter.children.first).zRotation
        let start = geometry.point(for: CGPoint(x: 0.5, y: 0.5))
        let end = geometry.point(for: CGPoint(x: 0.7, y: 0.3))
        let expected = atan2(end.y - start.y, end.x - start.x) - .pi / 2
        XCTAssertEqual(heading, expected, accuracy: 0.05, "still turning a second in")
    }

    func testFishNosesOutFromUnderALilyPadHeadFirst() async throws {
        var cover = PathLeg(
            destination: CGPoint(x: 0.5, y: 0.5), travel: 0.5, pause: 2, hides: false)
        cover.underCover = true
        cover.peek = CGPoint(x: 0.6, y: 0.5)
        let target = GameTarget(
            id: UUID(), kind: .fish, start: CGPoint(x: 0.4, y: 0.6),
            legs: [
                cover,
                PathLeg(destination: CGPoint(x: 0.3, y: 0.3), travel: 1, pause: 0, hides: false),
            ])
        let plan = try XCTUnwrap(CritterActions.plan(for: target, in: geometry))
        let artwork = try XCTUnwrap(
            PlayfieldTextures.critter(.fish, variant: .standard, size: geometry.targetSize))
        let critter = CritterNode()
        view.scene?.addChild(critter)
        critter.play(
            plan, artwork: artwork, caughtArtwork: nil, layer: 0, canTakeCover: false,
            spawnOrder: 0, completion: {})
        // Out at the peek, two thirds of the way through the hover.
        try await Task.sleep(nanoseconds: 1_800_000_000)
        let peek = geometry.point(for: CGPoint(x: 0.6, y: 0.5))
        XCTAssertEqual(critter.position.x, peek.x, accuracy: 3)
        XCTAssertEqual(critter.position.y, peek.y, accuracy: 3)
        let heading = try XCTUnwrap(critter.children.first).zRotation
        XCTAssertEqual(heading, -.pi / 2, accuracy: 0.05, "faces the way it peeks")
    }

    func testBirdFacesWhereItFliesOff() async throws {
        // The walk before the flight has no pause, as a path's last leg never does.
        let target = GameTarget(
            id: UUID(), kind: .bird, start: CGPoint(x: 0.5, y: 0.5),
            legs: [
                PathLeg(destination: CGPoint(x: 0.5, y: 0.4), travel: 0.2, pause: 0, hides: false),
                PathLeg(
                    destination: CGPoint(x: 1, y: 0.4), travel: 1, pause: 0, hides: false,
                    exits: true, flies: true),
            ])
        let plan = try XCTUnwrap(CritterActions.plan(for: target, in: geometry))
        let artwork = try XCTUnwrap(
            PlayfieldTextures.critter(.bird, variant: .standard, size: geometry.targetSize))
        let critter = CritterNode()
        view.scene?.addChild(critter)
        critter.play(
            plan, artwork: artwork, caughtArtwork: nil, layer: 0, canTakeCover: false,
            spawnOrder: 0, completion: {})
        // A quarter of the way into the flight.
        try await Task.sleep(nanoseconds: 450_000_000)
        let heading = try XCTUnwrap(critter.children.first).zRotation
        XCTAssertEqual(heading, -.pi / 2, accuracy: 0.05, "faces right, toward the edge")
    }

    func testFeatherSways() async throws {
        // A sway turns the hit box, which widens it.
        let widths = try await samples(of: .feather, seconds: 1.2) { $0.hitFrame.width }
        XCTAssertGreaterThan(spread(widths), 1, "\(widths)")
    }
}
