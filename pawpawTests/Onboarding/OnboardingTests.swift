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

    func testPracticeTargetEntersFromAnEdge() {
        let interactor = OnboardingInteractor(
            profileStorage: MockProfileStorage(), settings: MockSettingsStorage())
        for _ in 0..<20 {
            let target = interactor.makePracticeTarget(kind: .mouse)
            XCTAssertEqual(target.kind, .mouse)
            XCTAssertFalse(target.legs.isEmpty)
            let start = target.start
            XCTAssertTrue([0, 1].contains(start.x) || [0, 1].contains(start.y), "\(start)")
        }
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

    func testLoadShowsStaticTextReservesSpaceAndShowsFirstPage() {
        presenter.viewDidLoad()
        XCTAssertEqual(view.staticTexts, [OnboardingPresenter.staticText])
        XCTAssertEqual(view.reserved, [OnboardingPresenter.reservedTexts])
        XCTAssertEqual(view.pages.last?.progress.index, 0)
        XCTAssertEqual(view.pages.last?.progress.count, pageCount + 1)
    }

    func testProgressCopyAndControls() {
        presenter.viewDidLoad()
        let first = view.pages.last?.progress
        XCTAssertEqual(first?.stepLabel, "Step 1 of \(pageCount + 1)")
        XCTAssertEqual(first?.nextTitle, OnboardingPresenter.nextTitle)
        XCTAssertEqual(first?.canGoBack, false)
        XCTAssertEqual(first?.canSwipeForward, true)

        presenter.didTapSkip()
        let setup = view.catSetups.last
        XCTAssertEqual(setup?.progress.stepLabel, "Step \(pageCount + 1) of \(pageCount + 1)")
        XCTAssertEqual(setup?.progress.nextTitle, OnboardingPresenter.finishTitle)
        XCTAssertEqual(setup?.progress.canGoBack, true)
        XCTAssertEqual(setup?.progress.canSwipeForward, false, "Only the button finishes")
        XCTAssertEqual(setup?.setup.body, OnboardingPresenter.catSetupBody)
    }

    func testBackStopsAtFirstPage() {
        presenter.viewDidLoad()
        presenter.didTapBack()
        XCTAssertEqual(view.pages.map(\.progress.index), [0, 0])
    }

    func testNextWalksPagesThenCatSetup() {
        presenter.viewDidLoad()
        for _ in 0..<pageCount { presenter.didTapNext() }
        XCTAssertEqual(view.pages.map(\.progress.index), Array(0..<pageCount))
        XCTAssertEqual(view.catSetups.count, 1)
        XCTAssertEqual(view.catSetups.last?.progress.index, pageCount)
        XCTAssertEqual(
            view.catSetups.last?.setup.face, .calico, "Starts from the cat's current face")
    }

    func testBackFromCatSetupReturnsToLastPage() {
        presenter.didTapSkip()
        presenter.didTapBack()
        XCTAssertEqual(view.pages.last?.progress.index, pageCount - 1)
    }

    func testSkipGoesToCatSetupNotPastIt() {
        presenter.viewDidLoad()
        presenter.didTapSkip()
        XCTAssertEqual(view.catSetups.count, 1)
        XCTAssertEqual(router.finishCount, 0)
    }

    func testCatSetupKeepsTheChosenFace() {
        presenter.didTapSkip()
        presenter.didSelectFace(.gray)
        presenter.didTapBack()
        presenter.didTapNext()
        XCTAssertEqual(view.catSetups.last?.setup.face, .gray)
    }

    func testDoneNeedsAName() {
        presenter.didTapSkip()
        presenter.didChangeCatName("   ")
        presenter.didTapNext()
        XCTAssertEqual(view.nameRequired, [OnboardingPresenter.nameRequiredAnnouncement])
        XCTAssertTrue(interactor.savedCats.isEmpty)
        XCTAssertEqual(interactor.completeCount, 0)
        XCTAssertEqual(router.finishCount, 0)
    }

    func testDoneSavesThenFinishesAfterTheCelebration() {
        finishWithMochi()
        XCTAssertEqual(interactor.savedCats.map(\.name), ["Mochi"])
        XCTAssertEqual(interactor.savedCats.map(\.face), [.gray])
        XCTAssertEqual(interactor.completeCount, 1)
        XCTAssertEqual(view.celebrationCount, 1)
        XCTAssertEqual(router.finishCount, 0)
        view.pendingCelebration?()
        XCTAssertEqual(router.finishCount, 1)
    }

    func testDoneUsesTheCurrentFaceWhenNoneIsPicked() {
        presenter.didTapSkip()
        presenter.didChangeCatName("Mochi")
        presenter.didTapNext()
        XCTAssertEqual(interactor.savedCats.map(\.face), [.calico])
    }

    func testDoneOnlyFinishesOnce() {
        finishWithMochi()
        presenter.didTapNext()
        presenter.didTapSkip()
        XCTAssertEqual(interactor.savedCats.count, 1)
        XCTAssertEqual(interactor.completeCount, 1)
        XCTAssertEqual(view.celebrationCount, 1)
    }

    func testDoneFinishesWithoutAView() {
        presenter.view = nil
        finishWithMochi()
        XCTAssertEqual(router.finishCount, 1)
    }

    func testSkippingCatSetupFinishesWithoutSaving() {
        presenter.didTapSkip()
        presenter.didTapSkip()
        XCTAssertTrue(interactor.savedCats.isEmpty)
        XCTAssertEqual(interactor.completeCount, 1)
        XCTAssertEqual(router.finishCount, 1)
    }

    private func finishWithMochi() {
        presenter.didTapSkip()
        presenter.didChangeCatName("Mochi")
        presenter.didSelectFace(.gray)
        presenter.didTapNext()
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

    func testPracticeTargetsCycleThroughKinds() {
        let interactor = OnboardingInteractorSpy()
        presenter.interactor = interactor
        let kinds = OnboardingPresenter.practiceKinds
        let targets = (0...kinds.count).compactMap { _ in presenter.nextPracticeTarget() }
        XCTAssertEqual(targets.map(\.kind), kinds + [kinds[0]])
        XCTAssertEqual(interactor.practiceKinds, kinds + [kinds[0]])
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
        XCTAssertEqual(view.catSetups.last?.setup.title, "Who's playing?")
        presenter.didChangeCatName("Mochi")
        presenter.didTapBack()
        presenter.didTapNext()
        XCTAssertEqual(view.catSetups.last?.setup.title, "Hi, Mochi!")
    }

    private func goToHoldPage() {
        while view.pages.last?.page.interaction != .holdToLeave { presenter.didTapNext() }
    }
}
