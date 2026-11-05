//
//  ProfilesTests.swift
//  pawpawTests
//

import XCTest

@testable import pawpaw

@MainActor
final class ProfilesInteractorTests: XCTestCase {
    private var storage: MockProfileStorage!
    private var favorites: [UUID: TargetKind] = [:]
    private var output: ProfilesInteractorOutputSpy!
    private var interactor: ProfilesInteractor!

    override func setUp() async throws {
        try await super.setUp()
        storage = MockProfileStorage()
        output = ProfilesInteractorOutputSpy()
        interactor = ProfilesInteractor(
            profileStorage: storage,
            makeStatsStorage: { [unowned self] id in
                let stats = MockStatsStorage()
                if let kind = self.favorites[id] { stats.stats.record(catches: [kind: 1]) }
                return stats
            })
        interactor.presenter = output
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

    func testForwardsActions() {
        presenter.viewWillAppear()
        presenter.didSelectProfile(id: UUID())
        presenter.didAddProfile(name: "A", face: .gray, disabledKinds: [])
        presenter.didUpdateProfile(id: UUID(), name: "B", face: .gray, disabledKinds: [])
        presenter.didConfirmDelete(id: UUID())
        presenter.didTapBack()
        XCTAssertEqual(
            interactor.calls,
            ["fetchProfiles", "selectProfile", "addProfile:A", "updateProfile:B", "deleteProfile"])
        XCTAssertEqual(router.backCount, 1)
    }

    func testRows() throws {
        let tom = CatProfile(name: "Tom", face: .orange, disabledKinds: [.laser])
        let luna = CatProfile(name: "Luna", face: .siamese)
        presenter.didFetchProfiles(
            [
                ProfileEntry(profile: tom, favorite: .mouse),
                ProfileEntry(profile: luna, favorite: nil),
            ],
            activeID: luna.id)

        let shown = try XCTUnwrap(view.shown.last)
        XCTAssertTrue(shown.canDelete)
        XCTAssertEqual(
            shown.rows,
            [
                ProfileRow(
                    id: tom.id, name: "Tom", face: .orange, subtitle: "Loves mice", isActive: false,
                    disabledKinds: [.laser]),
                ProfileRow(
                    id: luna.id, name: "Luna", face: .siamese, subtitle: "No favorite yet",
                    isActive: true),
            ])
    }

    func testSingleCatCantBeDeleted() {
        let tom = CatProfile(name: "Tom")
        presenter.didFetchProfiles([ProfileEntry(profile: tom, favorite: nil)], activeID: tom.id)
        XCTAssertEqual(view.shown.last?.canDelete, false)
    }
}
