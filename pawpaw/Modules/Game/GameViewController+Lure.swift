//
//  GameViewController+Lure.swift
//  pawpaw
//

import UIKit

/// Between timed rounds, one critter roams the field with the results card as cover.
/// Catching it is how a cat asks for another round.
extension GameViewController {
    /// Lets a pounce that was under way when the round ended land without counting.
    static let lureReadyDelay: TimeInterval = 1.0
    /// With no touches for this long the lure wanders off and the screen may sleep.
    static let lureIdleTimeout: TimeInterval = 45

    func setupLure() {
        scene.onTapLure = { [weak self] in self?.presenter?.didTapLure() }
        scene.onLureLoopEnd = { [weak self] point in self?.presenter?.didFinishLureLoop(at: point) }
        scene.onLureDiscard = { [weak self] in
            // A resize moved the card; wait for layout to settle, then bring the lure back.
            DispatchQueue.main.async { self?.reportLureCover() }
        }
        scene.onTouch = { [weak self] in
            guard let self, self.scene.hasLure, !self.scene.isLureLeaving else { return }
            self.restartLureIdleTimer()
        }
    }

    func showLureWhenReady() {
        cancelLure()
        let generation = lureGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.lureReadyDelay) { [weak self] in
            guard let self, generation == self.lureGeneration else { return }
            self.reportLureCover()
        }
    }

    func showLure(_ target: GameTarget, isLeaving: Bool) {
        scene.showLure(target, isLeaving: isLeaving)
        if isLeaving {
            lureIdleWork?.cancel()
            lureIdleWork = nil
            setScreenAwake(false)
        } else if lureIdleWork == nil {
            restartLureIdleTimer()
            setScreenAwake(true)
        }
    }

    func showLureCaught() {
        cancelLure()
        scene.catchLure()
    }

    func showFinalCatch(_ message: String) {
        resultTitleLabel.text = message
        setScreenAwake(false)
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    /// Stops pending lure timers, e.g. when a round starts or the game closes.
    func cancelLure() {
        lureGeneration += 1
        lureIdleWork?.cancel()
        lureIdleWork = nil
    }

    private func reportLureCover() {
        guard isShowingResult, let card = resultCard else { return }
        view.layoutIfNeeded()
        let cover = scene.setLureObstacle(viewRect: card.convert(card.bounds, to: gameArea))
        presenter?.didBecomeReadyForLure(cover: cover, lastTouch: scene.lastTouchNormalized)
    }

    /// The idle wait only counts time in the foreground.
    func pauseLureIdleTimer() {
        lureIdleWork?.cancel()
        lureIdleWork = nil
    }

    func resumeLureIdleTimer() {
        guard scene.hasLure, !scene.isLureLeaving else { return }
        restartLureIdleTimer()
    }

    private func restartLureIdleTimer() {
        lureIdleWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, let point = self.scene.lureNormalizedPosition else { return }
            self.lureIdleWork = nil
            self.presenter?.didIdleWithLure(at: point)
        }
        lureIdleWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.lureIdleTimeout, execute: work)
    }
}
