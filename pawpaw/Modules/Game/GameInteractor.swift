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
    /// Catches of one kind in a row before that kind gets a new look.
    static let habituationStreak = 3

    weak var presenter: GameInteractorOutputProtocol?

    private let storage: ScoreStorage
    private let settings: SettingsStorage
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
    private var lastCaughtKind: TargetKind?
    private var catchStreak = 0
    /// How many times each kind's look has been refreshed this round.
    private var refreshes: [TargetKind: Int] = [:]

    /// Seconds per lure leg, travel and freeze together: about 0.7× a round critter's pace.
    static let lureLegDuration: TimeInterval = 1.4
    /// The final catch is slower still, so it's easy.
    static let finalLureLegDuration: TimeInterval = 2.0
    private var lure: GameTarget?
    private var lureCover: LureCover?
    private var lureIsFinal = false
    /// Changes every results screen, as a new look keeps a cat interested.
    private var lastLureKind: TargetKind?
    /// Rounds started in a row by catching the lure.
    private var autoRounds = 0

    private var isPlaying: Bool {
        isRunning && !isPaused
    }

    init(
        storage: ScoreStorage,
        statsStorage: StatsStorage,
        settings: SettingsStorage,
        mode: SessionMode,
        theme: PlayfieldTheme,
        enabledKinds: [TargetKind] = TargetKind.allCases
    ) {
        self.storage = storage
        self.statsStorage = statsStorage
        self.settings = settings
        self.mode = mode
        self.theme = theme
        let suited = enabledKinds.filter { $0.canAppear(on: theme) }
        // Only empty for legacy profiles with just single-theme critters enabled; fall back to every suitable critter.
        self.spawnableKinds = suited.isEmpty ? TargetKind.allCases.filter { $0.canAppear(on: theme) } : suited
    }

    deinit {
        clockTimer?.invalidate()
        spawnTimer?.invalidate()
    }

    // MARK: GameInteractorInputProtocol
    var shouldShowExitTip: Bool {
        !settings.hasLearnedHoldToExit
    }

    func recordExitHoldLearned() {
        settings.hasLearnedHoldToExit = true
    }

    func startGame() {
        invalidateTimers()
        activeTargets.removeAll()
        score = 0
        catches = 0
        unsavedCatches = [:]
        roundIsRecorded = false
        difficulty.reset()
        lastCaughtKind = nil
        catchStreak = 0
        refreshes = [:]
        lure = nil
        lureCover = nil
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
        lure = nil
    }

    func pauseGame() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        invalidateTimers()
        // The app may be killed in the background.
        saveCatches()
        // On-screen critters stay in play; the view freezes them until the round resumes.
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
        recordStreak(of: target.kind)
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

    // MARK: Lure

    func startLure(cover: LureCover, awayFrom touch: CGPoint?) {
        guard !isRunning else { return }
        lureCover = cover
        // After a relayout the same critter comes back, so a final catch stays final.
        let kind: TargetKind
        if let current = lure {
            kind = current.kind
        } else {
            kind = randomLureKind()
            lastLureKind = kind
            lureIsFinal = !settings.afterRound.continues(afterAutoRounds: autoRounds)
        }
        let start = kind.movementStyle.surfaces
            ? MovementPlanner.lureOpenPoint(from: CGPoint(x: 0.5, y: 0.5), style: kind.movementStyle, avoiding: cover.frame)
            : MovementPlanner.lureEntryPoint(awayFrom: touch, avoiding: cover.frame)
        moveLure(kind: kind, from: start, leadIn: MovementPlanner.leadIn(for: kind.movementStyle))
    }

    func continueLure(from point: CGPoint) {
        guard !isRunning, let current = lure else { return }
        // Inside the border, so the planner doesn't take the start for an off-screen entry.
        let start = CGPoint(x: min(max(point.x, 0.01), 0.99), y: min(max(point.y, 0.01), 0.99))
        moveLure(kind: current.kind, from: start, leadIn: 0)
    }

    /// It can still be caught on the way out.
    func sendLureAway(from point: CGPoint) {
        guard !isRunning, let current = lure else { return }
        let target = GameTarget(
            id: current.id,
            kind: current.kind,
            start: point,
            legs: MovementPlanner.lureExitLegs(from: point, style: current.kind.movementStyle)
        )
        lure = target
        presenter?.didMoveLure(target, isLeaving: true)
    }

    func catchLure() {
        guard !isRunning, lure != nil else { return }
        lure = nil
        let startsNextRound = !lureIsFinal
        if startsNextRound { autoRounds += 1 }
        presenter?.didCatchLure(startsNextRound: startsNextRound)
    }

    func resetAutoRounds() {
        autoRounds = 0
    }

    private func moveLure(kind: TargetKind, from start: CGPoint, leadIn: TimeInterval) {
        let target = GameTarget(
            id: lure?.id ?? UUID(),
            kind: kind,
            start: start,
            legs: MovementPlanner.lureLegs(
                from: start,
                style: kind.movementStyle,
                legDuration: lureIsFinal ? Self.finalLureLegDuration : Self.lureLegDuration,
                cover: lureCover,
                isFinal: lureIsFinal
            ),
            leadIn: leadIn
        )
        lure = target
        presenter?.didMoveLure(target, isLeaving: false)
    }

    /// Any enabled critter but the laser, which a cat can never truly catch, and not last time's.
    private func randomLureKind() -> TargetKind {
        let catchable = spawnableKinds.filter { $0 != .laser }
        let fresh = catchable.filter { $0 != lastLureKind }
        return fresh.randomElement() ?? catchable.randomElement() ?? .mouse
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
            ),
            leadIn: MovementPlanner.leadIn(for: kind.movementStyle),
            variant: CritterVariant.cycled(refreshes[kind, default: 0])
        )
        activeTargets[target.id] = target
        presenter?.didSpawnTarget(target)
    }

    /// Cats get used to prey they keep catching, and a new look restores interest (Hall, Bradshaw & Robinson, 2002).
    private func recordStreak(of kind: TargetKind) {
        catchStreak = kind == lastCaughtKind ? catchStreak + 1 : 1
        lastCaughtKind = kind
        guard catchStreak >= Self.habituationStreak else { return }
        refreshes[kind, default: 0] += 1
        catchStreak = 0
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
