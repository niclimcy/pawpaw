//
//  OnboardingPlayfieldView.swift
//  pawpaw
//

import SpriteKit
import UIKit

/// Practice field running the real `GameScene`, one unscored critter at a time.
final class OnboardingPlayfieldView: UIView {
    var onCatch: (() -> Void)?
    var nextTarget: (() -> GameTarget?)?

    private let skView = SKView()
    private let scene = GameScene(size: .zero)
    private static let respawnDelay: TimeInterval = 0.6
    private var currentTarget: GameTarget?
    private var isRunning = false
    private var isSpawnPending = false
    /// Invalidates pending spawns on stop.
    private var generation = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.background.withAlphaComponent(0.6)
        layer.cornerRadius = 20
        layer.borderWidth = 2
        layer.borderColor = Theme.gold.withAlphaComponent(0.3).cgColor
        clipsToBounds = true

        scene.tuning = .onboarding
        scene.theme = .wood
        scene.onTapTarget = { [weak self] id in self?.catchTarget(id) }
        scene.onExpire = { [weak self] _ in self?.targetLeft() }
        scene.onDiscard = { [weak self] _ in self?.targetLeft() }

        skView.allowsTransparency = true
        skView.backgroundColor = .clear
        skView.isMultipleTouchEnabled = true
        skView.ignoresSiblingOrder = true
        skView.preferredFramesPerSecond = 120
        skView.isPaused = true
        skView.presentScene(scene)
        skView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(skView)
        NSLayoutConstraint.activate([
            skView.topAnchor.constraint(equalTo: topAnchor),
            skView.bottomAnchor.constraint(equalTo: bottomAnchor),
            skView.leadingAnchor.constraint(equalTo: leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        isAccessibilityElement = true
        accessibilityLabel = "Practice field"
        accessibilityHint = "Double-tap to catch the critter."
        accessibilityTraits = .allowsDirectInteraction
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Retry once the field has a size.
        if isRunning, currentTarget == nil, !isSpawnPending { scheduleSpawn(after: 0) }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        skView.isPaused = false
        scene.resume()
        scheduleSpawn(after: 0.3)
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        isSpawnPending = false
        generation += 1
        currentTarget = nil
        scene.removeAllTargets()
        skView.isPaused = true
    }

    /// Async so the scene has picked up the view's size.
    private func scheduleSpawn(after delay: TimeInterval) {
        isSpawnPending = true
        let expected = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.generation == expected else { return }
            self.isSpawnPending = false
            self.spawn()
        }
    }

    private func spawn() {
        guard isRunning, currentTarget == nil, bounds.width > 0, bounds.height > 0,
            let target = nextTarget?()
        else { return }
        currentTarget = target
        scene.add(target)
    }

    private func catchTarget(_ id: UUID) {
        guard let target = currentTarget, target.id == id else { return }
        scene.caught(id: id, points: target.kind.points)
        nextCritter()
        onCatch?()
    }

    private func targetLeft() {
        guard currentTarget != nil else { return }
        nextCritter()
    }

    private func nextCritter() {
        currentTarget = nil
        guard isRunning else { return }
        scheduleSpawn(after: Self.respawnDelay)
    }

    /// VoiceOver can't chase a moving target.
    override func accessibilityActivate() -> Bool {
        guard let target = currentTarget else { return false }
        catchTarget(target.id)
        return true
    }
}
