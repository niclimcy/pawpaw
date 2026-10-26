//
//  GameInteractor.swift
//  pawpaw
//

import CoreGraphics
import Foundation

/// Holds the game rules: timers, spawning, scoring and high score persistence.
final class GameInteractor: GameInteractorInputProtocol {
    static let roundDuration = 60
    /// Cats focus on one thing at a time, so never show more than two critters at once.
    private let maxActiveTargets = 2
    /// How often we check for a free slot to spawn a new critter into.
    private let spawnInterval: TimeInterval = 1.0

    weak var presenter: GameInteractorOutputProtocol?

    private let storage: ScoreStorage
    private var activeTargets: [UUID: GameTarget] = [:]
    private var score = 0
    private var catches = 0
    private var timeRemaining = GameInteractor.roundDuration
    private var isRunning = false
    private var clockTimer: Timer?
    private var spawnTimer: Timer?

    init(storage: ScoreStorage) {
        self.storage = storage
    }

    deinit {
        invalidateTimers()
    }

    // MARK: GameInteractorInputProtocol
    func startGame() {
        invalidateTimers()
        activeTargets.removeAll()
        score = 0
        catches = 0
        timeRemaining = GameInteractor.roundDuration
        isRunning = true

        presenter?.didUpdateScore(score)
        presenter?.didUpdateTimeRemaining(timeRemaining)

        clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { [weak self] _ in
            self?.spawnTarget()
        }
        spawnTarget()
    }

    func stopGame() {
        isRunning = false
        invalidateTimers()
        activeTargets.removeAll()
    }

    func catchTarget(id: UUID) {
        guard isRunning, let target = activeTargets.removeValue(forKey: id) else { return }
        score += target.kind.points
        catches += 1
        presenter?.didCatchTarget(id: id, points: target.kind.points)
        presenter?.didUpdateScore(score)
    }

    func expireTarget(id: UUID) {
        activeTargets.removeValue(forKey: id)
    }

    // MARK: Private
    private func tick() {
        guard isRunning else { return }
        timeRemaining -= 1
        presenter?.didUpdateTimeRemaining(max(timeRemaining, 0))
        if timeRemaining <= 0 {
            finishGame()
        }
    }

    private func spawnTarget() {
        guard isRunning, activeTargets.count < maxActiveTargets else { return }
        let kind = randomKind()
        let start = randomPoint()
        var end = randomPoint()
        // Make sure the prey actually travels somewhere.
        while hypot(end.x - start.x, end.y - start.y) < 0.3 {
            end = randomPoint()
        }
        let target = GameTarget(
            id: UUID(),
            kind: kind,
            start: start,
            end: end,
            lifetime: TimeInterval.random(in: kind.lifetimeRange)
        )
        activeTargets[target.id] = target
        presenter?.didSpawnTarget(target)
    }

    private func finishGame() {
        isRunning = false
        invalidateTimers()
        activeTargets.removeAll()

        let previousBest = storage.highScore
        let isNewHighScore = score > previousBest
        if isNewHighScore {
            storage.saveHighScore(score)
        }
        let result = GameResult(
            score: score,
            catches: catches,
            highScore: max(score, previousBest),
            isNewHighScore: isNewHighScore
        )
        presenter?.didFinishGame(result)
    }

    private func randomKind() -> TargetKind {
        let total = TargetKind.allCases.reduce(0) { $0 + $1.weight }
        var roll = Int.random(in: 0..<total)
        for kind in TargetKind.allCases {
            if roll < kind.weight { return kind }
            roll -= kind.weight
        }
        return .mouse
    }

    private func randomPoint() -> CGPoint {
        CGPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1))
    }

    private func invalidateTimers() {
        clockTimer?.invalidate()
        spawnTimer?.invalidate()
        clockTimer = nil
        spawnTimer = nil
    }
}
