//
//  HomeInteractor.swift
//  pawpaw
//

import Foundation

final class HomeInteractor: HomeInteractorInputProtocol {
    weak var presenter: HomeInteractorOutputProtocol?
    private var storage: ScoreStorage

    init(storage: ScoreStorage) {
        self.storage = storage
    }

    var selectedMode: SessionMode {
        storage.selectedMode
    }

    func fetchState() {
        let mode = storage.selectedMode
        presenter?.didFetchState(
            mode: mode,
            theme: storage.selectedTheme,
            highScore: mode.hasHighScore ? storage.highScore(for: mode) : nil
        )
    }

    func selectTheme(_ theme: PlayfieldTheme) {
        storage.selectedTheme = theme
        fetchState()
    }

    func selectMode(_ mode: SessionMode) {
        storage.selectedMode = mode
        fetchState()
    }
}
