//
//  GameSpies.swift
//  pawpawTests
//

import UIKit

@testable import pawpaw

@MainActor
final class GameInteractorOutputSpy: GameInteractorOutputProtocol {
    private(set) var scores: [Int] = []
    private(set) var times: [Int?] = []
    private(set) var spawned: [GameTarget] = []
    private(set) var hidingSpots: [[CGPoint]] = []
    private(set) var caught: [(id: UUID, points: Int)] = []
    private(set) var results: [GameResult] = []
    private(set) var pauseCount = 0
    private(set) var resumeCount = 0
    private(set) var lureMoves: [(target: GameTarget, isLeaving: Bool)] = []
    private(set) var lureCatches: [Bool] = []

    func didUpdateScore(_ score: Int) { scores.append(score) }
    func didUpdateTimeRemaining(_ seconds: Int?) { times.append(seconds) }
    func didSpawnTarget(_ target: GameTarget) { spawned.append(target) }
    func didPlaceHidingSpots(_ points: [CGPoint]) { hidingSpots.append(points) }
    func didCatchTarget(id: UUID, points: Int) { caught.append((id, points)) }
    func didFinishGame(_ result: GameResult) { results.append(result) }
    func didPause() { pauseCount += 1 }
    func didResume() { resumeCount += 1 }
    func didMoveLure(_ target: GameTarget, isLeaving: Bool) {
        lureMoves.append((target, isLeaving))
    }
    func didCatchLure(startsNextRound: Bool) { lureCatches.append(startsNextRound) }
}

@MainActor
final class GameViewSpy: GameViewProtocol {
    var presenter: GamePresenterProtocol?
    private(set) var calls: [String] = []
    private(set) var scoreTexts: [String] = []
    private(set) var timeTexts: [String] = []
    private(set) var results: [(title: String, symbol: String?, details: String)] = []
    private(set) var finalCatches: [(message: String, symbol: String?)] = []
    private(set) var getReadyTips: [Bool] = []
    private(set) var getReadyCompletion: (() -> Void)?

    func showScore(_ text: String) { scoreTexts.append(text) }
    func showTime(_ text: String) { timeTexts.append(text) }
    func showTarget(_ target: GameTarget) { calls.append("showTarget") }
    func showHidingSpots(_ points: [CGPoint]) { calls.append("showHidingSpots") }
    func showCatch(targetID: UUID, points: Int) { calls.append("showCatch:\(points)") }
    func clearTargets() { calls.append("clearTargets") }
    func freezeTargets() { calls.append("freezeTargets") }
    func resumeTargets() { calls.append("resumeTargets") }
    func showResult(title: String, symbol: String?, details: String) {
        calls.append("showResult")
        results.append((title, symbol, details))
    }
    func hideResult() { calls.append("hideResult") }
    func showPaused() { calls.append("showPaused") }
    func showResumed() { calls.append("showResumed") }
    func showGetReady(showsExitTip: Bool, completion: @escaping () -> Void) {
        calls.append("showGetReady")
        getReadyTips.append(showsExitTip)
        getReadyCompletion = completion
    }
    func showLureWhenReady() { calls.append("showLureWhenReady") }
    func showLure(_ target: GameTarget, isLeaving: Bool) {
        calls.append("showLure:\(isLeaving)")
    }
    func showLureCaught() { calls.append("showLureCaught") }
    func showFinalCatch(_ message: String, symbol: String?) {
        calls.append("showFinalCatch")
        finalCatches.append((message, symbol))
    }
}

@MainActor
final class GameInteractorSpy: GameInteractorInputProtocol {
    var presenter: GameInteractorOutputProtocol?
    var shouldShowExitTip = false
    private(set) var calls: [String] = []
    private(set) var lureStarts: [(cover: LureCover, touch: CGPoint?)] = []

    func startGame() { calls.append("startGame") }
    func stopGame() { calls.append("stopGame") }
    func pauseGame() { calls.append("pauseGame") }
    func resumeGame() { calls.append("resumeGame") }
    func catchTarget(id: UUID) { calls.append("catchTarget") }
    func expireTarget(id: UUID) { calls.append("expireTarget") }
    func discardTarget(id: UUID) { calls.append("discardTarget") }
    func missTap() { calls.append("missTap") }
    func recordExitHoldLearned() { calls.append("recordExitHoldLearned") }
    func startLure(cover: LureCover, awayFrom touch: CGPoint?) {
        calls.append("startLure")
        lureStarts.append((cover, touch))
    }
    func continueLure(from point: CGPoint) { calls.append("continueLure") }
    func sendLureAway(from point: CGPoint) { calls.append("sendLureAway") }
    func catchLure() { calls.append("catchLure") }
    func resetAutoRounds() { calls.append("resetAutoRounds") }
}

@MainActor
final class GameRouterSpy: GameRouterProtocol {
    private(set) var navigatedHome = 0

    static func createModule(mode: SessionMode) -> UIViewController { UIViewController() }
    func navigateToHome(from view: GameViewProtocol?) { navigatedHome += 1 }
}
