//
//  OnboardingTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class OnboardingInteractorTests: XCTestCase {
    func testSaveCatRenamesTheActiveCatInsteadOfAdding() {
        let storage = MockProfileStorage()
        let interactor = OnboardingInteractor(
            profileStorage: storage, settings: MockSettingsStorage())
        interactor.saveCat(name: "Mochi", face: .calico)
        XCTAssertEqual(storage.profiles.count, 1)
        XCTAssertEqual(interactor.activeProfile.name, "Mochi")
        XCTAssertEqual(interactor.activeProfile.face, .calico)
    }

    func testCompleteOnboarding() {
        let settings = MockSettingsStorage()
        OnboardingInteractor(profileStorage: MockProfileStorage(), settings: settings)
            .completeOnboarding()
        XCTAssertTrue(settings.hasCompletedOnboarding)
    }
}

@MainActor
final class OnboardingPresenterTests: XCTestCase {
    private var view: OnboardingViewSpy!
    private var interactor: OnboardingInteractorSpy!
    private var router: OnboardingRouterSpy!
    private var presenter: OnboardingPresenter!
    private let pageCount = OnboardingPresenter.pages.count

    override func setUp() async throws {
        try await super.setUp()
        view = OnboardingViewSpy()
        interactor = OnboardingInteractorSpy()
        router = OnboardingRouterSpy()
        presenter = OnboardingPresenter()
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
    }

    func testPagesAreComplete() {
        XCTAssertFalse(OnboardingPresenter.pages.isEmpty)
        for page in OnboardingPresenter.pages {
            XCTAssertFalse(page.title.isEmpty)
            XCTAssertFalse(page.body.isEmpty)
        }
        XCTAssertEqual(
            OnboardingPresenter.pages.map(\.interaction), [.catchCritter, .countdown, .holdToLeave])
    }

    func testLoadReservesSpaceAndShowsFirstPage() {
        presenter.viewDidLoad()
        XCTAssertEqual(view.reserved, [OnboardingPresenter.reservedTexts])
        XCTAssertEqual(view.pages.last?.index, 0)
        XCTAssertEqual(view.pages.last?.count, pageCount + 1)
    }

    func testBackStopsAtFirstPage() {
        presenter.viewDidLoad()
        presenter.didTapBack()
        XCTAssertEqual(view.pages.map(\.index), [0, 0])
    }

    func testNextWalksPagesThenCatSetupAndStops() {
        presenter.viewDidLoad()
        for _ in 0..<(pageCount + 2) { presenter.didTapNext() }
        XCTAssertEqual(view.pages.map(\.index), Array(0..<pageCount))
        XCTAssertEqual(view.catSetups.count, 3)
        XCTAssertEqual(view.catSetups.last?.index, pageCount)
        XCTAssertEqual(view.catSetups.last?.face, .calico, "Starts from the cat's current face")
    }

    func testBackFromCatSetupReturnsToLastPage() {
        presenter.didTapSkip()
        presenter.didTapBack()
        XCTAssertEqual(view.pages.last?.index, pageCount - 1)
    }

    func testSkipGoesToCatSetupNotPastIt() {
        presenter.viewDidLoad()
        presenter.didTapSkip()
        XCTAssertEqual(view.catSetups.count, 1)
        XCTAssertEqual(router.finishCount, 0)
    }

    func testDoneNeedsAName() {
        presenter.didTapDone(name: "   ", face: .gray)
        XCTAssertEqual(view.nameRequiredCount, 1)
        XCTAssertTrue(interactor.savedCats.isEmpty)
        XCTAssertEqual(interactor.completeCount, 0)
        XCTAssertEqual(router.finishCount, 0)
    }

    func testDoneSavesThenFinishesAfterTheCelebration() {
        presenter.didTapDone(name: "Mochi", face: .gray)
        XCTAssertEqual(interactor.savedCats.map(\.name), ["Mochi"])
        XCTAssertEqual(interactor.savedCats.map(\.face), [.gray])
        XCTAssertEqual(interactor.completeCount, 1)
        XCTAssertEqual(view.celebrationCount, 1)
        XCTAssertEqual(router.finishCount, 0)
        view.pendingCelebration?()
        XCTAssertEqual(router.finishCount, 1)
    }

    func testDoneOnlyFinishesOnce() {
        presenter.didTapDone(name: "Mochi", face: .gray)
        presenter.didTapDone(name: "Mochi", face: .gray)
        presenter.didSkipCatSetup()
        XCTAssertEqual(interactor.savedCats.count, 1)
        XCTAssertEqual(interactor.completeCount, 1)
        XCTAssertEqual(view.celebrationCount, 1)
    }

    func testDoneFinishesWithoutAView() {
        presenter.view = nil
        presenter.didTapDone(name: "Mochi", face: .gray)
        XCTAssertEqual(router.finishCount, 1)
    }

    func testSkippingCatSetupFinishesWithoutSaving() {
        presenter.didSkipCatSetup()
        XCTAssertTrue(interactor.savedCats.isEmpty)
        XCTAssertEqual(interactor.completeCount, 1)
        XCTAssertEqual(router.finishCount, 1)
    }
}

@MainActor
final class OnboardingPracticeTests: XCTestCase {
    private var view: OnboardingViewSpy!
    private var presenter: OnboardingPresenter!

    override func setUp() async throws {
        try await super.setUp()
        view = OnboardingViewSpy()
        presenter = OnboardingPresenter()
        presenter.view = view
        presenter.interactor = OnboardingInteractorSpy()
        presenter.router = OnboardingRouterSpy()
        presenter.viewDidLoad()
    }

    func testReservedTextsCoverEveryFeedback() {
        let reserved = OnboardingPresenter.reservedTexts
        for text in OnboardingPresenter.catchFeedback + [
            OnboardingPresenter.houseTapFeedback, OnboardingPresenter.holdFeedback,
        ] {
            XCTAssertTrue(reserved.contains(text), text.title)
        }
    }

    func testCatchesCycleThroughFeedback() {
        let feedback = OnboardingPresenter.catchFeedback
        for _ in 0...feedback.count { presenter.didCatchPracticeCritter() }
        XCTAssertEqual(view.feedback.map(\.text), feedback + [feedback[0]])
        XCTAssertTrue(view.feedback.allSatisfy(\.celebrates))
    }

    func testCatchingIsNotNeededToMoveOn() {
        presenter.didTapNext()
        XCTAssertEqual(view.pages.last?.page.interaction, .countdown)
    }

    func testPracticeOnlyCountsOnItsOwnPage() {
        presenter.didTapHousePractice()
        presenter.didCompleteHoldPractice()
        presenter.didTapNext()
        presenter.didCatchPracticeCritter()
        XCTAssertTrue(view.feedback.isEmpty)
    }

    func testHouseTapHintsThenHoldSucceeds() {
        goToHoldPage()
        presenter.didTapHousePractice()
        presenter.didCompleteHoldPractice()
        XCTAssertEqual(
            view.feedback.map(\.text),
            [OnboardingPresenter.houseTapFeedback, OnboardingPresenter.holdFeedback])
        XCTAssertEqual(view.feedback.map(\.celebrates), [false, true])
    }

    func testTapAfterHoldKeepsTheSuccess() {
        goToHoldPage()
        presenter.didCompleteHoldPractice()
        presenter.didTapHousePractice()
        XCTAssertEqual(view.feedback.map(\.text), [OnboardingPresenter.holdFeedback])
    }

    func testReturningToHoldPageStartsOver() {
        goToHoldPage()
        presenter.didCompleteHoldPractice()
        presenter.didTapBack()
        presenter.didTapNext()
        presenter.didTapHousePractice()
        XCTAssertEqual(view.feedback.last?.text, OnboardingPresenter.houseTapFeedback)
    }

    func testCatSetupTitleGreetsTheCat() {
        XCTAssertEqual(OnboardingPresenter.catSetupTitle(for: ""), "Who's playing?")
        XCTAssertEqual(OnboardingPresenter.catSetupTitle(for: "   "), "Who's playing?")
        XCTAssertEqual(OnboardingPresenter.catSetupTitle(for: " Mochi "), "Hi, Mochi!")
    }

    func testTypingUpdatesTheTitleOnlyOnCatSetup() {
        presenter.didChangeCatName("Mo")
        XCTAssertTrue(view.catTitles.isEmpty)
        presenter.didTapSkip()
        presenter.didChangeCatName("Mochi")
        presenter.didChangeCatName("")
        XCTAssertEqual(view.catTitles, ["Hi, Mochi!", "Who's playing?"])
    }

    func testCatSetupKeepsTheGreetingAfterGoingBack() {
        presenter.didTapSkip()
        XCTAssertEqual(view.catSetups.last?.title, "Who's playing?")
        presenter.didChangeCatName("Mochi")
        presenter.didTapBack()
        presenter.didTapNext()
        XCTAssertEqual(view.catSetups.last?.title, "Hi, Mochi!")
    }

    private func goToHoldPage() {
        while view.pages.last?.page.interaction != .holdToLeave { presenter.didTapNext() }
    }
}
