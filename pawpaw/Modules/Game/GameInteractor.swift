//
//  GameInteractor.swift
//  pawpaw
//

import CoreGraphics
import Foundation

/// Holds the game rules: timers, spawning, scoring and high score persistence.
final class GameInteractor: GameInteractorInputProtocol {
    /// Cats focus on one thing at a time, so never show more than two critters at once.
    static let maxActiveTargets = 2
    /// How often we check for a free slot to spawn a new critter into.
    static let spawnInterval: TimeInterval = 1.0
    /// How many spots critters can duck under each round.
    static let hidingSpotCount = 2

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
    /// Catches not yet written to the lifetime stats.
    private var unsavedCatches: [TargetKind: Int] = [:]
    /// Whether this round already counts in the stats, from a save when the app was interrupted.
    private var roundIsRecorded = false
    private var timeRemaining = 0
    /// A round is under way (it may be paused).
    private var isRunning = false
    /// The app is in the background or interrupted, so the clock and the critters wait.
    private var isPaused = false
    private var clockTimer: Timer?
    private var spawnTimer: Timer?
    /// Speeds critters up for a cat that catches a lot, and slows them for one that keeps missing.
    private var difficulty: DifficultyTuner
    private var hidingSpots: [CGPoint] = []

    /// Taps, catches and the clock only count while the round is running and not paused.
    private var isPlaying: Bool {
        isRunning && !isPaused
    }

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
        // Profiles always keep a critter that lives on every background (`CatProfile.isPlayable`), so `suited`
        // is only empty for a profile saved by an older build with just the fish on. Play with every critter
        // that suits this background then, rather than leave the field empty.
        self.spawnableKinds = suited.isEmpty ? TargetKind.allCases.filter { $0.canAppear(on: theme) } : suited
        self.difficulty = DifficultyTuner(isEnabled: adaptiveDifficulty)
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
        // New hiding spots every round keep the playfield fresh.
        hidingSpots = MovementPlanner.hidingSpots(count: Self.hidingSpotCount)

        presenter?.didPlaceHidingSpots(hidingSpots)
        presenter?.didUpdateScore(score)
        // Relaxed play has no clock, so the view shows an open-ended symbol instead.
        presenter?.didUpdateTimeRemaining(mode.duration == nil ? nil : timeRemaining)

        startTimers()
        spawnTarget()
    }

    func stopGame() {
        // Leaving mid-session (always the case in relaxed mode) still counts what the cat caught.
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
        // The app may be closed while it is in the background, so save what the cat caught so far.
        saveCatches()
        // Critters on screen can't be frozen reliably, so they leave without counting as escapes,
        // and new ones come when play resumes.
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
        // Only a critter that ran off untouched during play counts as an escape.
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

    /// Adds catches not yet saved to the lifetime stats. A round without a catch isn't counted.
    /// The round itself is counted only the first time, even when it is saved in parts.
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
