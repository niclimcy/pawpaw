//
//  HomeInteractor.swift
//  pawpaw
//

import Foundation

final class HomeInteractor: HomeInteractorInputProtocol {
    weak var presenter: HomeInteractorOutputProtocol?

    private let profileStorage: ProfileStorage
    private let makeScoreStorage: (UUID) -> ScoreStorage
    private let makeStatsStorage: (UUID) -> StatsStorage

    /// Storages are built per call because the active cat can change while Home stays open.
    init(
        profileStorage: ProfileStorage,
        makeScoreStorage: @escaping (UUID) -> ScoreStorage,
        makeStatsStorage: @escaping (UUID) -> StatsStorage
    ) {
        self.profileStorage = profileStorage
        self.makeScoreStorage = makeScoreStorage
        self.makeStatsStorage = makeStatsStorage
    }

    private var storage: ScoreStorage {
        makeScoreStorage(profileStorage.activeProfile.id)
    }

    var selectedMode: SessionMode {
        storage.selectedMode
    }

    func fetchState() {
        let profile = profileStorage.activeProfile
        let scores = makeScoreStorage(profile.id)
        let mode = scores.selectedMode
        presenter?.didFetchState(
            mode: mode,
            theme: scores.selectedTheme,
            highScore: mode.hasHighScore ? scores.highScore(for: mode) : nil,
            profile: profile,
            favorite: makeStatsStorage(profile.id).stats.favoriteKind
        )
    }

    func selectTheme(_ theme: PlayfieldTheme) {
        var scores = storage
        scores.selectedTheme = theme
        fetchState()
    }

    func selectMode(_ mode: SessionMode) {
        var scores = storage
        scores.selectedMode = mode
        fetchState()
    }
}
