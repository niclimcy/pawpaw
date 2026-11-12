//
//  GameAccessibilityTests.swift
//  pawpawTests
//

import SpriteKit
import UIKit
import XCTest

@testable import pawpaw

@MainActor
final class GameAccessibilityTests: XCTestCase {
    private var sut: GameViewController!
    private var presenter: GamePresenterSpy!

    override func setUp() {
        super.setUp()
        // Built directly rather than through the router, which reads `UserDefaults.standard`.
        sut = GameViewController()
        presenter = GamePresenterSpy()
        sut.presenter = presenter
        sut.loadViewIfNeeded()
    }

    override func tearDown() {
        sut = nil
        presenter = nil
        super.tearDown()
    }

    func testPlayAgainButtonHasPlayAgainAction() throws {
        let button = try XCTUnwrap(findButton("playAgainButton"))

        let action = try XCTUnwrap(customAction(named: "Play again", on: button))
        XCTAssertTrue(perform(action))

        XCTAssertEqual(presenter.calls, ["didTapPlayAgain"])
    }

    func testHomeButtonsHaveLeaveGameAction() throws {
        for identifier in ["homeButton", "resultHomeButton"] {
            let button = try XCTUnwrap(findButton(identifier), identifier)

            let action = try XCTUnwrap(customAction(named: "Leave game", on: button), identifier)
            XCTAssertTrue(perform(action), identifier)
        }

        XCTAssertEqual(presenter.calls, ["didTapHome", "didTapHome"])
    }

    func testGameAreaAllowsDirectInteraction() throws {
        let gameArea = try XCTUnwrap(findView(SKView.self))

        XCTAssertTrue(gameArea.isAccessibilityElement)
        XCTAssertEqual(gameArea.accessibilityLabel, "Play field")
        XCTAssertTrue(gameArea.accessibilityTraits.contains(.allowsDirectInteraction))
    }

    func testHUDLabelsFollowTextSize() {
        XCTAssertTrue(sut.scoreLabel.adjustsFontForContentSizeCategory)
        XCTAssertTrue(sut.timeLabel.adjustsFontForContentSizeCategory)
    }

    func testOnlyTheOwnersPracticeFieldFollowsOwnerMotionSettings() {
        XCTAssertTrue(PlayfieldTuning.onboarding.isPlayedByOwner)
        XCTAssertFalse(PlayfieldTuning.standard.isPlayedByOwner)
        XCTAssertFalse(PlayfieldTuning.pocket.isPlayedByOwner)
        XCTAssertFalse(sut.scene.reducesMotion)
    }

    func testLureStaysCatchableWithVoiceOverWhileResultsShow() throws {
        sut.showResult(title: "Time's up!", symbol: nil, details: "Score: 10")

        XCTAssertFalse(sut.resultOverlay.accessibilityViewIsModal)
        let gameArea = try XCTUnwrap(findView(SKView.self))
        XCTAssertTrue(gameArea.accessibilityTraits.contains(.allowsDirectInteraction))
    }

    // MARK: Helpers
    private func findButton(_ identifier: String) -> UIButton? {
        findView(UIButton.self) { $0.accessibilityIdentifier == identifier }
    }

    private func findView<T: UIView>(
        _ type: T.Type, where matches: (T) -> Bool = { _ in true }
    ) -> T? {
        var queue: [UIView] = [sut.view]
        while !queue.isEmpty {
            let view = queue.removeFirst()
            if let match = view as? T, matches(match) { return match }
            queue.append(contentsOf: view.subviews)
        }
        return nil
    }

    private func customAction(
        named name: String, on view: UIView
    ) -> UIAccessibilityCustomAction? {
        view.accessibilityCustomActions?.first { $0.name == name }
    }

    private func perform(_ action: UIAccessibilityCustomAction) -> Bool {
        action.actionHandler?(action) ?? false
    }
}

@MainActor
private final class GamePresenterSpy: GamePresenterProtocol {
    var view: GameViewProtocol?
    var interactor: GameInteractorInputProtocol?
    var router: GameRouterProtocol?
    private(set) var calls: [String] = []

    func viewDidBecomeReady() {}
    func viewWillDisappear() {}
    func appWillResignActive() {}
    func appDidBecomeActive() {}
    func didTapTarget(id: UUID) {}
    func didExpireTarget(id: UUID) {}
    func didDiscardTarget(id: UUID) {}
    func didMissTap() {}
    func didTapPlayAgain() { calls.append("didTapPlayAgain") }
    func didTapHome() { calls.append("didTapHome") }
    func didBecomeReadyForLure(cover: LureCover, lastTouch: CGPoint?) {}
    func didFinishLureLoop(at point: CGPoint) {}
    func didIdleWithLure(at point: CGPoint) {}
    func didTapLure() {}
}
