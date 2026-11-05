//
//  HomeProfilesSpies.swift
//  pawpawTests
//

import UIKit

@testable import pawpaw

// MARK: - Home

@MainActor
final class HomeViewSpy: HomeViewProtocol {
    var presenter: HomePresenterProtocol?
    private(set) var modes: [SessionMode] = []
    private(set) var themes: [PlayfieldTheme] = []
    private(set) var afterRounds: [(mode: AfterRoundMode, isAvailable: Bool)] = []
    private(set) var highScores: [Int?] = []
    private(set) var profiles: [(name: String, face: CatFace, favorite: String?)] = []
    private(set) var notes: [String?] = []

    func showMode(_ mode: SessionMode) { modes.append(mode) }
    func showTheme(_ theme: PlayfieldTheme) { themes.append(theme) }
    func showAfterRound(_ afterRound: AfterRoundMode, isAvailable: Bool) {
        afterRounds.append((afterRound, isAvailable))
    }
    func showHighScore(_ score: Int?) { highScores.append(score) }
    func showProfile(name: String, face: CatFace, favorite: String?) {
        profiles.append((name, face, favorite))
    }
    func showPlayfieldNote(_ text: String?) { notes.append(text) }
}

@MainActor
final class HomeInteractorSpy: HomeInteractorInputProtocol {
    var presenter: HomeInteractorOutputProtocol?
    var selectedMode: SessionMode = .long
    private(set) var calls: [String] = []

    func fetchState() { calls.append("fetchState") }
    func selectMode(_ mode: SessionMode) { calls.append("selectMode:\(mode.rawValue)") }
    func selectTheme(_ theme: PlayfieldTheme) { calls.append("selectTheme:\(theme.rawValue)") }
    func selectAfterRound(_ afterRound: AfterRoundMode) {
        calls.append("selectAfterRound:\(afterRound.rawValue)")
    }
}

@MainActor
final class HomeInteractorOutputSpy: HomeInteractorOutputProtocol {
    struct State {
        let mode: SessionMode
        let theme: PlayfieldTheme
        let afterRound: AfterRoundMode
        let highScore: Int?
        let profile: CatProfile
        let favorite: TargetKind?
    }
    private(set) var states: [State] = []

    func didFetchState(
        mode: SessionMode, theme: PlayfieldTheme, afterRound: AfterRoundMode, highScore: Int?,
        profile: CatProfile, favorite: TargetKind?
    ) {
        states.append(
            State(
                mode: mode, theme: theme, afterRound: afterRound, highScore: highScore,
                profile: profile, favorite: favorite))
    }
}

@MainActor
final class HomeRouterSpy: HomeRouterProtocol {
    private(set) var gameModes: [SessionMode] = []
    private(set) var statsCount = 0
    private(set) var profilesCount = 0

    static func createModule() -> UIViewController { UIViewController() }
    func navigateToGame(from view: HomeViewProtocol?, mode: SessionMode) { gameModes.append(mode) }
    func navigateToStats(from view: HomeViewProtocol?) { statsCount += 1 }
    func navigateToProfiles(from view: HomeViewProtocol?) { profilesCount += 1 }
}

// MARK: - Profiles

@MainActor
final class ProfilesViewSpy: ProfilesViewProtocol {
    var presenter: ProfilesPresenterProtocol?
    private(set) var shown: [(rows: [ProfileRow], canDelete: Bool)] = []

    func showProfiles(_ rows: [ProfileRow], canDelete: Bool) { shown.append((rows, canDelete)) }
}

@MainActor
final class ProfilesInteractorSpy: ProfilesInteractorInputProtocol {
    var presenter: ProfilesInteractorOutputProtocol?
    private(set) var calls: [String] = []

    func fetchProfiles() { calls.append("fetchProfiles") }
    func selectProfile(id: UUID) { calls.append("selectProfile") }
    func addProfile(name: String, face: CatFace, disabledKinds: Set<TargetKind>) {
        calls.append("addProfile:\(name)")
    }
    func updateProfile(id: UUID, name: String, face: CatFace, disabledKinds: Set<TargetKind>) {
        calls.append("updateProfile:\(name)")
    }
    func deleteProfile(id: UUID) { calls.append("deleteProfile") }
}

@MainActor
final class ProfilesInteractorOutputSpy: ProfilesInteractorOutputProtocol {
    private(set) var fetched: [(entries: [ProfileEntry], activeID: UUID)] = []

    func didFetchProfiles(_ entries: [ProfileEntry], activeID: UUID) {
        fetched.append((entries, activeID))
    }
}

@MainActor
final class ProfilesRouterSpy: ProfilesRouterProtocol {
    private(set) var backCount = 0

    static func createModule() -> UIViewController { UIViewController() }
    func navigateBack(from view: ProfilesViewProtocol?) { backCount += 1 }
}
