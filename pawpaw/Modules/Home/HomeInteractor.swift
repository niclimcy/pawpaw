//
//  HomeInteractor.swift
//  pawpaw
//

import Foundation

final class HomeInteractor: HomeInteractorInputProtocol {
    weak var presenter: HomeInteractorOutputProtocol?

    private let profileStorage: ProfileStorage
    private let settings: SettingsStorage
    private let makeScoreStorage: (UUID) -> ScoreStorage
    private let makeStatsStorage: (UUID) -> StatsStorage

    /// Per-cat storages are built per call because the active cat can change while Home stays open.
    init(
        profileStorage: ProfileStorage,
        settings: SettingsStorage,
        makeScoreStorage: @escaping (UUID) -> ScoreStorage,
        makeStatsStorage: @escaping (UUID) -> StatsStorage
    ) {
        self.profileStorage = profileStorage
        self.settings = settings
        self.makeScoreStorage = makeScoreStorage
        self.makeStatsStorage = makeStatsStorage
    }

    var selectedMode: SessionMode {
        settings.selectedMode
    }

    func fetchState() {
        let profile = profileStorage.activeProfile
        let mode = settings.selectedMode
        presenter?.didFetchState(
            mode: mode,
            theme: settings.selectedTheme,
            highScore: mode.hasHighScore ? makeScoreStorage(profile.id).highScore(for: mode) : nil,
            profile: profile,
            favorite: makeStatsStorage(profile.id).stats.favoriteKind
        )
    }

    func selectTheme(_ theme: PlayfieldTheme) {
        settings.selectedTheme = theme
        fetchState()
    }

    func selectMode(_ mode: SessionMode) {
        settings.selectedMode = mode
        fetchState()
    }
}
