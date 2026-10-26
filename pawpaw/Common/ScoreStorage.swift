//
//  ScoreStorage.swift
//  pawpaw
//

import Foundation

protocol ScoreStorage {
    var highScore: Int { get }
    func saveHighScore(_ score: Int)
}

final class UserDefaultsScoreStorage: ScoreStorage {
    private let defaults: UserDefaults
    private let key = "pawpaw.highScore"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var highScore: Int {
        defaults.integer(forKey: key)
    }

    func saveHighScore(_ score: Int) {
        defaults.set(score, forKey: key)
    }
}
