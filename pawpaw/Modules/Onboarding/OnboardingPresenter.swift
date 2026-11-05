//
//  OnboardingPresenter.swift
//  pawpaw
//

import Foundation

final class OnboardingPresenter: OnboardingPresenterProtocol {
    // TODO: To remove after swift bug is resolved.
    nonisolated deinit {}

    weak var view: OnboardingViewProtocol?
    var interactor: OnboardingInteractorInputProtocol?
    var router: OnboardingRouterProtocol?

    private static let setupBody =
        "Pick a time and tap PLAY. Lay the device flat before the countdown ends."

    static let pages = [
        OnboardingPage(
            title: "Try it yourself",
            body: "Tap a critter to catch it. Your cat does the same with a paw.",
            interaction: .catchCritter
        ),
        OnboardingPage(
            title: "You set it up",
            body: [setupBody, PlayfieldTuning.current.screenNote.map { "\($0)." }]
                .compactMap { $0 }.joined(separator: " "),
            interaction: .countdown
        ),
        OnboardingPage(
            title: "Hold to leave",
            body: "Cats tap, so a tap on the house does nothing. Try holding it.",
            interaction: .holdToLeave
        ),
    ]

    /// Cycled through on each practice catch.
    static let catchFeedback = [
        OnboardingText(title: "Got one!", body: "Now picture your cat doing that."),
        OnboardingText(title: "Nice", body: "Miss and they hop away."),
        OnboardingText(title: "Again!", body: "Each critter moves a bit differently."),
    ]

    static let houseTapFeedback = OnboardingText(
        title: "Nothing happens",
        body: "That's all a paw can do. Now hold it."
    )

    static let holdFeedback = OnboardingText(
        title: "That's it",
        body: "Only a hold leaves a game."
    )

    static let unnamedCatTitle = "Who's playing?"

    static func catSetupTitle(for name: String) -> String {
        CatProfile.cleaned(name).map { "Hi, \($0)!" } ?? unnamedCatTitle
    }

    static var reservedTexts: [OnboardingText] {
        pages.map(\.text) + catchFeedback + [houseTapFeedback, holdFeedback]
    }

    /// The intro pages plus the cat setup.
    private static var stepCount: Int { pages.count + 1 }

    private var index = 0
    private var catchCount = 0
    private var hasHeldHouse = false
    private var isFinishing = false
    /// Kept so returning to the cat setup keeps the greeting.
    private var catName = ""

    // MARK: OnboardingPresenterProtocol
    func viewDidLoad() {
        view?.reserveSpace(for: Self.reservedTexts)
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
        guard !isFinishing else { return }
        guard CatProfile.cleaned(name) != nil else {
            view?.showNameRequired()
            return
        }
        isFinishing = true
        interactor?.saveCat(name: name, face: face)
        interactor?.completeOnboarding()
        guard let view else {
            router?.finish()
            return
        }
        view.showFinishCelebration { [weak self] in self?.router?.finish() }
    }

    func didSkipCatSetup() {
        guard !isFinishing else { return }
        isFinishing = true
        interactor?.completeOnboarding()
        router?.finish()
    }

    // MARK: Practice
    func didCatchPracticeCritter() {
        guard currentInteraction == .catchCritter else { return }
        let feedback = Self.catchFeedback[catchCount % Self.catchFeedback.count]
        catchCount += 1
        view?.showPracticeFeedback(feedback, celebrates: true)
    }

    /// Ignored after a successful hold, so the success text stays.
    func didTapHousePractice() {
        guard currentInteraction == .holdToLeave, !hasHeldHouse else { return }
        view?.showPracticeFeedback(Self.houseTapFeedback, celebrates: false)
    }

    func didCompleteHoldPractice() {
        guard currentInteraction == .holdToLeave else { return }
        hasHeldHouse = true
        view?.showPracticeFeedback(Self.holdFeedback, celebrates: true)
    }

    func didChangeCatName(_ name: String) {
        catName = name
        guard index == Self.pages.count else { return }
        view?.updateCatSetupTitle(Self.catSetupTitle(for: name))
    }

    // MARK: Private
    private var currentInteraction: OnboardingInteraction? {
        index < Self.pages.count ? Self.pages[index].interaction : nil
    }

    private func showCurrentStep() {
        guard index < Self.pages.count else {
            let face = interactor?.activeProfile.face ?? .orange
            view?.showCatSetup(
                face: face,
                title: Self.catSetupTitle(for: catName),
                index: index,
                count: Self.stepCount
            )
            return
        }
        hasHeldHouse = false
        view?.showPage(Self.pages[index], index: index, count: Self.stepCount)
    }
}
