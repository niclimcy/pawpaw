//
//  ProfilesTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class ProfilesInteractorTests: XCTestCase {
    private var storage: MockProfileStorage!
    private var settings: MockSettingsStorage!
    private var favorites: [UUID: TargetKind] = [:]
    private var output: ProfilesInteractorOutputSpy!
    private var interactor: ProfilesInteractor!

    override func setUp() async throws {
        try await super.setUp()
        storage = MockProfileStorage()
        settings = MockSettingsStorage()
        output = ProfilesInteractorOutputSpy()
        interactor = ProfilesInteractor(
            profileStorage: storage,
            settings: settings,
            makeStatsStorage: { [unowned self] id in
                let stats = MockStatsStorage()
                if let kind = self.favorites[id] { stats.stats.record(catches: [kind: 1]) }
                return stats
            })
        interactor.presenter = output
    }

    func testFetchThemeReadsSettings() {
        settings.selectedTheme = .pond
        interactor.fetchTheme()
        XCTAssertEqual(output.themes, [.pond])
    }

    func testFetchIncludesEachCatsFavorite() throws {
        favorites[storage.profiles[0].id] = .cricket
        interactor.fetchProfiles()
        let fetched = try XCTUnwrap(output.fetched.last)
        XCTAssertEqual(fetched.entries.map(\.favorite), [.cricket])
        XCTAssertEqual(fetched.activeID, storage.profiles[0].id)
    }

    func testAddSetsKindsAndMakesItActive() throws {
        interactor.addProfile(name: "Mochi", face: .white, disabledKinds: [.bug])
        let added = try XCTUnwrap(storage.profiles.last)
        XCTAssertEqual(added.name, "Mochi")
        XCTAssertEqual(added.disabledKinds, [.bug])
        XCTAssertEqual(storage.activeID, added.id)
        XCTAssertEqual(output.fetched.last?.activeID, added.id)
    }

    func testAddWithBlankNameDoesNothing() {
        interactor.addProfile(name: "  ", face: .white, disabledKinds: [])
        XCTAssertEqual(storage.profiles.count, 1)
        XCTAssertTrue(output.fetched.isEmpty)
    }

    func testUpdateSelectAndDeleteRefetch() throws {
        let id = storage.profiles[0].id
        interactor.updateProfile(id: id, name: "Tommy", face: .black, disabledKinds: [.laser])
        XCTAssertEqual(storage.profiles[0].name, "Tommy")
        XCTAssertEqual(storage.profiles[0].disabledKinds, [.laser])

        interactor.addProfile(name: "Mochi", face: .white, disabledKinds: [])
        interactor.selectProfile(id: id)
        XCTAssertEqual(storage.activeID, id)

        interactor.deleteProfile(id: id)
        XCTAssertEqual(storage.profiles.map(\.name), ["Mochi"])
        XCTAssertEqual(output.fetched.count, 4)
    }
}

@MainActor
final class ProfilesPresenterTests: XCTestCase {
    private var view: ProfilesViewSpy!
    private var interactor: ProfilesInteractorSpy!
    private var router: ProfilesRouterSpy!
    private var presenter: ProfilesPresenter!

    override func setUp() async throws {
        try await super.setUp()
        view = ProfilesViewSpy()
        interactor = ProfilesInteractorSpy()
        router = ProfilesRouterSpy()
        presenter = ProfilesPresenter()
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
    }

    private let tom = CatProfile(name: "Tom", face: .orange, disabledKinds: [.laser])
    private let luna = CatProfile(name: "Luna", face: .siamese)

    private func fetchTwoCats() {
        presenter.didFetchProfiles(
            [
                ProfileEntry(profile: tom, favorite: nil),
                ProfileEntry(profile: luna, favorite: nil),
            ],
            activeID: tom.id)
    }

    func testViewDidLoadFetchesThemeAndShowsIt() {
        presenter.viewDidLoad()
        presenter.didFetchTheme(.snow)
        XCTAssertEqual(interactor.calls, ["fetchTheme"])
        XCTAssertEqual(view.themes, [.snow])
    }

    func testForwardsActions() {
        presenter.viewWillAppear()
        presenter.didSelectProfile(id: UUID())
        presenter.didTapBack()
        XCTAssertEqual(interactor.calls, ["fetchProfiles", "selectProfile"])
        XCTAssertEqual(router.backCount, 1)
    }

    func testRows() throws {
        presenter.didFetchProfiles(
            [
                ProfileEntry(profile: tom, favorite: .mouse),
                ProfileEntry(profile: luna, favorite: nil),
            ],
            activeID: luna.id)

        let shown = try XCTUnwrap(view.shown.last)
        XCTAssertEqual(
            shown,
            [
                ProfileRow(
                    id: tom.id, name: "Tom", face: .orange, subtitle: "Loves mice", isActive: false,
                    disabledKinds: [.laser]),
                ProfileRow(
                    id: luna.id, name: "Luna", face: .siamese, subtitle: "No favorite yet",
                    isActive: true),
            ])
    }

    func testSingleCatCantBeDeleted() throws {
        presenter.didFetchProfiles([ProfileEntry(profile: tom, favorite: nil)], activeID: tom.id)
        presenter.didTapEdit(id: tom.id)
        XCTAssertEqual(try XCTUnwrap(view.editors.last).canDelete, false)
    }

    // MARK: Add

    func testAddOpensEmptyEditorWithFirstUnusedFace() throws {
        fetchTwoCats()
        presenter.didTapAdd()
        XCTAssertEqual(
            view.editors,
            [
                ProfileEditorContent(
                    title: "Add a cat", name: "", face: .gray, disabledKinds: [], isAdding: true,
                    canDelete: false)
            ])
    }

    func testAddFallsBackToOrangeWhenEveryFaceIsTaken() throws {
        let entries = CatFace.allCases.map {
            ProfileEntry(profile: CatProfile(name: "A", face: $0), favorite: nil)
        }
        presenter.didFetchProfiles(entries, activeID: UUID())
        presenter.didTapAdd()
        XCTAssertEqual(try XCTUnwrap(view.editors.last).face, .orange)
    }

    func testSaveAddsWithTheTogglesMade() {
        fetchTwoCats()
        presenter.didTapAdd()
        presenter.didToggleCritter(.bug)
        presenter.didTapSave(name: "Mochi", face: .white)
        XCTAssertEqual(view.hideEditorCount, 1)
        XCTAssertEqual(interactor.added.count, 1)
        XCTAssertEqual(interactor.added.first?.name, "Mochi")
        XCTAssertEqual(interactor.added.first?.face, .white)
        XCTAssertEqual(interactor.added.first?.disabledKinds, [.bug])
    }

    func testSaveWithBlankNameWhenAddingAsksForOne() {
        presenter.didTapAdd()
        presenter.didTapSave(name: "  ", face: .white)
        XCTAssertEqual(view.nameRequiredCount, 1)
        XCTAssertEqual(view.hideEditorCount, 0)
        XCTAssertTrue(interactor.added.isEmpty)

        presenter.didTapSave(name: "Mochi", face: .white)
        XCTAssertEqual(interactor.added.count, 1)
    }

    // MARK: Edit

    func testEditOpensEditorForTheRow() throws {
        fetchTwoCats()
        presenter.didTapEdit(id: tom.id)
        XCTAssertEqual(
            view.editors,
            [
                ProfileEditorContent(
                    title: "Edit cat", name: "Tom", face: .orange, disabledKinds: [.laser],
                    isAdding: false, canDelete: true)
            ])
    }

    func testEditingUnknownCatDoesNothing() {
        fetchTwoCats()
        presenter.didTapEdit(id: UUID())
        XCTAssertTrue(view.editors.isEmpty)
    }

    func testSaveUpdatesEvenWithBlankName() {
        fetchTwoCats()
        presenter.didTapEdit(id: luna.id)
        presenter.didTapSave(name: "", face: .black)
        XCTAssertEqual(view.nameRequiredCount, 0)
        XCTAssertEqual(interactor.updated.count, 1)
        XCTAssertEqual(interactor.updated.first?.id, luna.id)
        XCTAssertEqual(interactor.updated.first?.face, .black)
        XCTAssertEqual(view.hideEditorCount, 1)
    }

    func testDeleteRemovesTheCatBeingEdited() {
        fetchTwoCats()
        presenter.didTapEdit(id: luna.id)
        presenter.didConfirmDelete()
        XCTAssertEqual(interactor.deletedIDs, [luna.id])
        XCTAssertEqual(view.hideEditorCount, 1)
    }

    func testDeleteWhileAddingDoesNothing() {
        presenter.didTapAdd()
        presenter.didConfirmDelete()
        XCTAssertTrue(interactor.deletedIDs.isEmpty)
    }

    func testCancelClosesWithoutSaving() {
        fetchTwoCats()
        presenter.didTapEdit(id: luna.id)
        presenter.didTapCancel()
        presenter.didTapSave(name: "Luna", face: .black)
        XCTAssertEqual(view.hideEditorCount, 1)
        XCTAssertTrue(interactor.updated.isEmpty)
    }

    // MARK: Critter toggles

    /// Owners can't switch off the last valid critter.
    func testToggleRefusesToLeaveOnlyTheLaser() {
        let allButLaserAndBug = Set(TargetKind.allCases.filter { $0 != .laser && $0 != .bug })
        let cat = CatProfile(name: "Tom", disabledKinds: allButLaserAndBug)
        presenter.didFetchProfiles([ProfileEntry(profile: cat, favorite: nil)], activeID: cat.id)
        presenter.didTapEdit(id: cat.id)

        presenter.didToggleCritter(.bug)
        XCTAssertEqual(view.refused.map(\.kind), [.bug])
        XCTAssertEqual(view.refused.first?.hint, ProfilesPresenter.critterHint)
        XCTAssertTrue(view.critters.isEmpty)

        presenter.didTapSave(name: "Tom", face: .orange)
        XCTAssertEqual(interactor.updated.first?.disabledKinds, allButLaserAndBug)
    }

    func testToggleOffAndBackOn() {
        presenter.didTapAdd()
        presenter.didToggleCritter(.mouse)
        presenter.didToggleCritter(.mouse)
        XCTAssertEqual(view.critters, [[.mouse], []])
    }

    func testTurningACritterBackOnAlwaysWorks() {
        let allButLaserAndBug = Set(TargetKind.allCases.filter { $0 != .laser && $0 != .bug })
        let cat = CatProfile(name: "Tom", disabledKinds: allButLaserAndBug)
        presenter.didFetchProfiles([ProfileEntry(profile: cat, favorite: nil)], activeID: cat.id)
        presenter.didTapEdit(id: cat.id)

        presenter.didToggleCritter(.laser)
        presenter.didToggleCritter(.mouse)
        let withLaserOff = allButLaserAndBug.union([.laser])
        XCTAssertEqual(view.critters, [withLaserOff, withLaserOff.subtracting([.mouse])])
    }

    func testToggleOutsideEditingDoesNothing() {
        presenter.didToggleCritter(.mouse)
        XCTAssertTrue(view.critters.isEmpty)
        XCTAssertTrue(view.refused.isEmpty)
    }
}
