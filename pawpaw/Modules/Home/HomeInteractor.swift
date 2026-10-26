//
//  HomeInteractor.swift
//  pawpaw
//

import Foundation

final class HomeInteractor: HomeInteractorInputProtocol {
    weak var presenter: HomeInteractorOutputProtocol?
    private let storage: ScoreStorage

    init(storage: ScoreStorage) {
        self.storage = storage
    }

    func fetchHighScore() {
        presenter?.didFetchHighScore(storage.highScore)
    }
}
