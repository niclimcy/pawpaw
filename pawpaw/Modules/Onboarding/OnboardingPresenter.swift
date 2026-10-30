//
//  OnboardingPresenter.swift
//  pawpaw
//

import Foundation

final class OnboardingPresenter: OnboardingPresenterProtocol {
    weak var view: OnboardingViewProtocol?
    var interactor: OnboardingInteractorInputProtocol?
    var router: OnboardingRouterProtocol?

    static let pages = [
        OnboardingPage(
            title: "A game for your cat",
            body: "Little critters scurry across the screen, and your cat catches them with a tap of the paw.",
            imageNames: ["critter_mouse", "critter_butterfly", "critter_feather"]
        ),
        OnboardingPage(
            title: "You set it up, your cat plays",
            body: "Choose how long to play and where, then tap PLAY. Set your device down flat while it counts 3, 2, 1.",
            imageNames: ["critter_bug", "critter_cricket"]
        ),
        OnboardingPage(
            title: "Only you can leave a game",
            body: "To leave, press and hold the house button. A quick tap from a paw won't do it.",
            imageNames: [],
            symbolName: "house.fill"
        )
    ]

    /// The intro pages plus the cat setup.
    private static var stepCount: Int { pages.count + 1 }

    private var index = 0

    // MARK: OnboardingPresenterProtocol
    func viewDidLoad() {
        view?.reserveSpace(for: Self.pages)
        showCurrentStep()
    }

    func didTapNext() {
        index = min(index + 1, Self.pages.count)
        showCurrentStep()
    }

    func didTapBack() {
        index = max(index - 1, 0)
        showCurrentStep()
    }

    /// Skips the intro, not the cat setup.
    func didTapSkip() {
        index = Self.pages.count
        showCurrentStep()
    }

    func didTapDone(name: String, face: CatFace) {
        guard CatProfile.cleaned(name) != nil else {
            view?.showNameRequired()
            return
        }
        interactor?.saveCat(name: name, face: face)
        finish()
    }

    func didSkipCatSetup() {
        finish()
    }

    // MARK: Private
    private func showCurrentStep() {
        guard index < Self.pages.count else {
            let face = interactor?.activeProfile.face ?? .orange
            view?.showCatSetup(face: face, index: index, count: Self.stepCount)
            return
        }
        view?.showPage(Self.pages[index], index: index, count: Self.stepCount)
    }

    private func finish() {
        interactor?.completeOnboarding()
        router?.finish()
    }
}
