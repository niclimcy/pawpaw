//
//  StatsOnboardingSpies.swift
//  pawpawTests
//

import UIKit

@testable import pawpaw

// MARK: - Stats

@MainActor
final class StatsViewSpy: StatsViewProtocol {
    var presenter: StatsPresenterProtocol?
    private(set) var viewModels: [StatsViewModel] = []

    func showStats(_ viewModel: StatsViewModel) { viewModels.append(viewModel) }
}

@MainActor
final class StatsInteractorSpy: StatsInteractorInputProtocol {
    var presenter: StatsInteractorOutputProtocol?
    private(set) var calls: [String] = []

    func fetchStats() { calls.append("fetchStats") }
    func resetStats() { calls.append("resetStats") }
}

@MainActor
final class StatsInteractorOutputSpy: StatsInteractorOutputProtocol {
    private(set) var fetched:
        [(stats: PlayStats, bestScores: [(mode: SessionMode, score: Int)], profile: CatProfile)] =
            []

    func didFetchStats(
        _ stats: PlayStats, bestScores: [(mode: SessionMode, score: Int)], profile: CatProfile
    ) {
        fetched.append((stats, bestScores, profile))
    }
}

@MainActor
final class StatsRouterSpy: StatsRouterProtocol {
    private(set) var backCount = 0

    static func createModule() -> UIViewController { UIViewController() }
    func navigateBack(from view: StatsViewProtocol?) { backCount += 1 }
}

// MARK: - Onboarding

@MainActor
final class OnboardingViewSpy: OnboardingViewProtocol {
    var presenter: OnboardingPresenterProtocol?
    private(set) var reserved: [[OnboardingText]] = []
    private(set) var pages: [(page: OnboardingPage, index: Int, count: Int)] = []
    private(set) var feedback: [(text: OnboardingText, celebrates: Bool)] = []
    private(set) var catSetups: [(face: CatFace, title: String, index: Int, count: Int)] = []
    private(set) var catTitles: [String] = []
    private(set) var nameRequiredCount = 0
    private(set) var celebrationCount = 0
    /// Held back so tests can finish the celebration when they choose.
    private(set) var pendingCelebration: (() -> Void)?

    func reserveSpace(for texts: [OnboardingText]) { reserved.append(texts) }
    func showPage(_ page: OnboardingPage, index: Int, count: Int) {
        pages.append((page, index, count))
    }
    func showPracticeFeedback(_ text: OnboardingText, celebrates: Bool) {
        feedback.append((text, celebrates))
    }
    func showCatSetup(face: CatFace, title: String, index: Int, count: Int) {
        catSetups.append((face, title, index, count))
    }
    func updateCatSetupTitle(_ title: String) { catTitles.append(title) }
    func showNameRequired() { nameRequiredCount += 1 }
    func showFinishCelebration(completion: @escaping () -> Void) {
        celebrationCount += 1
        pendingCelebration = completion
    }
}

@MainActor
final class OnboardingInteractorSpy: OnboardingInteractorInputProtocol {
    var activeProfile = CatProfile(name: "Tom", face: .calico)
    private(set) var savedCats: [(name: String, face: CatFace)] = []
    private(set) var completeCount = 0

    func saveCat(name: String, face: CatFace) { savedCats.append((name, face)) }
    func completeOnboarding() { completeCount += 1 }
}

@MainActor
final class OnboardingRouterSpy: OnboardingRouterProtocol {
    private(set) var finishCount = 0

    static func createModule(onFinish: @escaping () -> Void) -> UIViewController {
        UIViewController()
    }
    func finish() { finishCount += 1 }
}
