//
//  GameInteractor.swift
//  pawpaw
//

import CoreGraphics
import Foundation

final class GameInteractor: GameInteractorInputProtocol {
    static let maxActiveTargets = 2
    static let spawnInterval: TimeInterval = 1.0
    static let hidingSpotCount = 2

    weak var presenter: GameInteractorOutputProtocol?

    private let storage: ScoreStorage
    private let mode: SessionMode
    private let statsStorage: StatsStorage
    private let spawnableKinds: [TargetKind]
    private let theme: PlayfieldTheme
    private var activeTargets: [UUID: GameTarget] = [:]
    private var score = 0
    private var catches = 0
    private var unsavedCatches: [TargetKind: Int] = [:]
    /// Set once an interrupted round has been saved, so it isn't counted twice.
    private var roundIsRecorded = false
    private var timeRemaining = 0
    private var isRunning = false
    private var isPaused = false
    private var clockTimer: Timer?
    private var spawnTimer: Timer?
    private var difficulty = DifficultyTuner()
    private var hidingSpots: [CGPoint] = []

    private var isPlaying: Bool {
        isRunning && !isPaused
    }

    init(
        storage: ScoreStorage,
        statsStorage: StatsStorage,
        mode: SessionMode,
        theme: PlayfieldTheme,
        enabledKinds: [TargetKind] = TargetKind.allCases
    ) {
        self.storage = storage
        self.statsStorage = statsStorage
        self.mode = mode
        self.theme = theme
        let suited = enabledKinds.filter { $0.canAppear(on: theme) }
        // Only empty for legacy profiles with just the fish enabled; fall back to every suitable critter.
        self.spawnableKinds = suited.isEmpty ? TargetKind.allCases.filter { $0.canAppear(on: theme) } : suited
    }

    deinit {
        clockTimer?.invalidate()
        spawnTimer?.invalidate()
    }

    // MARK: GameInteractorInputProtocol
    func startGame() {
        invalidateTimers()
        activeTargets.removeAll()
        score = 0
        catches = 0
        unsavedCatches = [:]
        roundIsRecorded = false
        difficulty.reset()
        timeRemaining = mode.duration ?? 0
        isRunning = true
        isPaused = false
        hidingSpots = MovementPlanner.hidingSpots(count: Self.hidingSpotCount)

        presenter?.didPlaceHidingSpots(hidingSpots)
        presenter?.didUpdateScore(score)
        presenter?.didUpdateTimeRemaining(mode.duration == nil ? nil : timeRemaining)

        startTimers()
        spawnTarget()
    }

    func stopGame() {
        if isRunning { saveCatches() }
        isRunning = false
        isPaused = false
        invalidateTimers()
        activeTargets.removeAll()
    }

    func pauseGame() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        invalidateTimers()
        // The app may be killed in the background.
        saveCatches()
        // Running animations can't be frozen reliably, so on-screen critters are dropped.
        activeTargets.removeAll()
        presenter?.didPause()
    }

    func resumeGame() {
        guard isRunning, isPaused else { return }
        isPaused = false
        presenter?.didResume()
        startTimers()
        spawnTarget()
    }

    func catchTarget(id: UUID) {
        guard isPlaying, let target = activeTargets.removeValue(forKey: id) else { return }
        score += target.kind.points
        catches += 1
        unsavedCatches[target.kind, default: 0] += 1
        difficulty.recordCatch()
        presenter?.didCatchTarget(id: id, points: target.kind.points)
        presenter?.didUpdateScore(score)
    }

    func expireTarget(id: UUID) {
        guard isPlaying, activeTargets.removeValue(forKey: id) != nil else { return }
        difficulty.recordEscape()
    }

    func discardTarget(id: UUID) {
        activeTargets.removeValue(forKey: id)
    }

    func missTap() {
        guard isPlaying else { return }
        difficulty.recordMiss()
    }

    // MARK: Private
    private func startTimers() {
        invalidateTimers()
        if mode.duration != nil {
            clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.tick()
            }
        }
        spawnTimer = Timer.scheduledTimer(withTimeInterval: Self.spawnInterval, repeats: true) { [weak self] _ in
            self?.spawnTarget()
        }
    }

    private func tick() {
        guard isPlaying else { return }
        timeRemaining -= 1
        presenter?.didUpdateTimeRemaining(max(timeRemaining, 0))
        if timeRemaining <= 0 {
            finishGame()
        }
    }

    private func spawnTarget() {
        guard isPlaying, activeTargets.count < Self.maxActiveTargets else { return }
        let kind = randomKind()
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

    /// Rounds without a catch aren't recorded.
    private func saveCatches() {
        guard !unsavedCatches.isEmpty else { return }
        statsStorage.record(catches: unsavedCatches, isNewRound: !roundIsRecorded)
        roundIsRecorded = true
        unsavedCatches = [:]
    }

    private func finishGame() {
        saveCatches()
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
        guard total > 0, let fallback = spawnableKinds.first else { return .mouse }
        var roll = Int.random(in: 0..<total)
        for kind in spawnableKinds {
            if roll < kind.weight { return kind }
            roll -= kind.weight
        }
        return fallback
    }

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
