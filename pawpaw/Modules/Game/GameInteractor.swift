//
//  GameInteractor.swift
//  pawpaw
//

import CoreGraphics
import Foundation

/// Holds the game rules: timers, spawning, scoring and high score persistence.
final class GameInteractor: GameInteractorInputProtocol {
    /// Cats focus on one thing at a time, so never show more than two critters at once.
    private let maxActiveTargets = 2
    /// How often we check for a free slot to spawn a new critter into.
    private let spawnInterval: TimeInterval = 1.0

    weak var presenter: GameInteractorOutputProtocol?

    private let storage: ScoreStorage
    private let mode: SessionMode
    private let statsStorage: StatsStorage
    /// Critters that can spawn on this background (fish only live in the pond).
    private let spawnableKinds: [TargetKind]
    /// Decides which critters can use the hiding spots (only fish go under lily pads).
    private let theme: PlayfieldTheme
    private var activeTargets: [UUID: GameTarget] = [:]
    private var score = 0
    private var catches = 0
    private var catchesByKind: [TargetKind: Int] = [:]
    private var timeRemaining = 0
    private var isRunning = false
    private var clockTimer: Timer?
    private var spawnTimer: Timer?
    /// Speeds critters up for a cat that catches a lot, and slows them for one that keeps missing.
    private var difficulty: DifficultyTuner
    /// How many spots critters can duck under each round.
    private let hidingSpotCount = 2
    private var hidingSpots: [CGPoint] = []

    init(
        storage: ScoreStorage,
        statsStorage: StatsStorage,
        mode: SessionMode,
        theme: PlayfieldTheme,
        enabledKinds: [TargetKind] = TargetKind.allCases,
        adaptiveDifficulty: Bool = true
    ) {
        self.storage = storage
        self.statsStorage = statsStorage
        self.mode = mode
        self.theme = theme
        let suited = enabledKinds.filter { $0.canAppear(on: theme) }
        // If the cat's picks don't live on this background (only fish, on the crate), play with everything
        // that does, so the field is never empty.
        self.spawnableKinds = suited.isEmpty ? TargetKind.allCases.filter { $0.canAppear(on: theme) } : suited
        self.difficulty = DifficultyTuner(isEnabled: adaptiveDifficulty)
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
        catchesByKind = [:]
        difficulty.reset()
        timeRemaining = mode.duration ?? 0
        isRunning = true
        // New hiding spots every round keep the playfield fresh.
        hidingSpots = MovementPlanner.hidingSpots(count: hidingSpotCount)

        presenter?.didPlaceHidingSpots(hidingSpots)
        presenter?.didUpdateScore(score)
        // Relaxed play has no clock, so the view shows an open-ended symbol instead.
        presenter?.didUpdateTimeRemaining(mode.duration == nil ? nil : timeRemaining)

        if mode.duration != nil {
            clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.tick()
            }
        }
        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { [weak self] _ in
            self?.spawnTarget()
        }
        spawnTarget()
    }

    func stopGame() {
        // Leaving mid-session (always the case in relaxed mode) still counts what the cat caught.
        if isRunning { recordSession() }
        isRunning = false
        invalidateTimers()
        activeTargets.removeAll()
    }

    func catchTarget(id: UUID) {
        guard isRunning, let target = activeTargets.removeValue(forKey: id) else { return }
        score += target.kind.points
        catches += 1
        catchesByKind[target.kind, default: 0] += 1
        difficulty.recordCatch()
        presenter?.didCatchTarget(id: id, points: target.kind.points)
        presenter?.didUpdateScore(score)
    }

    func expireTarget(id: UUID) {
        // Only a critter that ran off untouched counts as an escape.
        guard isRunning, activeTargets.removeValue(forKey: id) != nil else { return }
        difficulty.recordEscape()
    }

    func missTap() {
        guard isRunning else { return }
        difficulty.recordMiss()
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
        // Prey emerges from the edge of the crate; fish rise from somewhere inside the pond.
        let start = kind.movementStyle.surfaces ? randomInnerPoint() : randomEdgePoint()
        let target = GameTarget(
            id: UUID(),
            kind: kind,
            start: start,
            legs: MovementPlanner.legs(
                from: start,
                style: kind.movementStyle,
                duration: difficulty.lifetime(for: TimeInterval.random(in: kind.lifetimeRange)),
                coverSpots: theme.allowsCover(for: kind.movementStyle) ? hidingSpots : []
            )
        )
        activeTargets[target.id] = target
        presenter?.didSpawnTarget(target)
    }

    /// Adds this session to the lifetime stats. Sessions without a catch are skipped.
    private func recordSession() {
        guard catches > 0 else { return }
        statsStorage.record(catches: catchesByKind)
    }

    private func finishGame() {
        recordSession()
        isRunning = false
        invalidateTimers()
        activeTargets.removeAll()

        let previousBest = storage.highScore(for: mode)
        let isNewHighScore = mode.hasHighScore && score > previousBest
        if isNewHighScore {
            storage.saveHighScore(score, for: mode)
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
        let total = spawnableKinds.reduce(0) { $0 + $1.weight }
        guard total > 0 else { return .mouse }
        var roll = Int.random(in: 0..<total)
        for kind in spawnableKinds {
            if roll < kind.weight { return kind }
            roll -= kind.weight
        }
        return .mouse
    }

    /// A spot well inside the field, away from the edges.
    private func randomInnerPoint() -> CGPoint {
        CGPoint(x: CGFloat.random(in: 0.2...0.8), y: CGFloat.random(in: 0.2...0.8))
    }

    private func randomEdgePoint() -> CGPoint {
        let along = CGFloat.random(in: 0...1)
        let edge: CGFloat = Bool.random() ? 0 : 1
        return Bool.random() ? CGPoint(x: edge, y: along) : CGPoint(x: along, y: edge)
    }

    private func invalidateTimers() {
        clockTimer?.invalidate()
        spawnTimer?.invalidate()
        clockTimer = nil
        spawnTimer = nil
    }
}
