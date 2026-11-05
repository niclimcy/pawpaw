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
            XCTAssertTrue(!page.imageNames.isEmpty || page.symbolName != nil, page.title)
        }
    }

    func testLoadReservesSpaceAndShowsFirstPage() {
        presenter.viewDidLoad()
        XCTAssertEqual(view.reserved, [OnboardingPresenter.pages])
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

    func testDoneSavesAndFinishes() {
        presenter.didTapDone(name: "Mochi", face: .gray)
        XCTAssertEqual(interactor.savedCats.map(\.name), ["Mochi"])
        XCTAssertEqual(interactor.savedCats.map(\.face), [.gray])
        XCTAssertEqual(interactor.completeCount, 1)
        XCTAssertEqual(router.finishCount, 1)
    }

    func testSkippingCatSetupFinishesWithoutSaving() {
        presenter.didSkipCatSetup()
        XCTAssertTrue(interactor.savedCats.isEmpty)
        XCTAssertEqual(interactor.completeCount, 1)
        XCTAssertEqual(router.finishCount, 1)
    }
}
