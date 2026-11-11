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

    static let staticText = OnboardingStaticText(
        skipTitle: "Hold to Skip",
        skipHint: "Press and hold to skip",
        skipAction: "Skip",
        holdPrompt: "Hold me",
        countdownDescription: "Lay the device flat. It counts 3, 2, 1, then your cat plays."
    )

    static let catSetupBody = "Name your cat and pick a face. You can add more cats later."
    static let nameRequiredAnnouncement = "Add your cat's name, or hold Skip to add one later"
    static let nextTitle = "Next"
    static let finishTitle = "Let's go"

    static let practiceKinds: [TargetKind] = [
        .mouse, .bug, .butterfly, .cricket, .feather, .ribbon,
    ]

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
    private var practiceKindIndex = 0
    private var hasHeldHouse = false
    private var isFinishing = false
    /// Kept so returning to the cat setup keeps the greeting and the pick.
    private var catName = ""
    private var catFace: CatFace?

    // MARK: OnboardingPresenterProtocol
    func viewDidLoad() {
        view?.showStaticText(Self.staticText)
        view?.reserveSpace(for: Self.reservedTexts)
        showCurrentStep()
    }

    func didTapNext() {
        guard !isOnCatSetup else {
            finishWithCat()
            return
        }
        index += 1
        showCurrentStep()
    }

    func didTapBack() {
        index = max(index - 1, 0)
        showCurrentStep()
    }

    func didTapSkip() {
        guard !isOnCatSetup else {
            finishWithoutCat()
            return
        }
        index = Self.pages.count
        showCurrentStep()
    }

    func didChangeCatName(_ name: String) {
        catName = name
        guard isOnCatSetup else { return }
        view?.updateCatSetupTitle(Self.catSetupTitle(for: name))
    }

    func didSelectFace(_ face: CatFace) {
        catFace = face
    }

    // MARK: Practice
    func nextPracticeTarget() -> GameTarget? {
        let kind = Self.practiceKinds[practiceKindIndex % Self.practiceKinds.count]
        practiceKindIndex += 1
        return interactor?.makePracticeTarget(kind: kind)
    }

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

    // MARK: Private
    private var isOnCatSetup: Bool { index == Self.pages.count }

    private var currentInteraction: OnboardingInteraction? {
        index < Self.pages.count ? Self.pages[index].interaction : nil
    }

    private var currentFace: CatFace {
        catFace ?? interactor?.activeProfile.face ?? .orange
    }

    private var progress: OnboardingProgress {
        OnboardingProgress(
            index: index,
            count: Self.stepCount,
            stepLabel: "Step \(index + 1) of \(Self.stepCount)",
            nextTitle: isOnCatSetup ? Self.finishTitle : Self.nextTitle,
            canSwipeForward: !isOnCatSetup
        )
    }

    private func showCurrentStep() {
        guard !isOnCatSetup else {
            let setup = OnboardingCatSetup(
                face: currentFace,
                title: Self.catSetupTitle(for: catName),
                body: Self.catSetupBody
            )
            view?.showCatSetup(setup, progress: progress)
            return
        }
        hasHeldHouse = false
        view?.showPage(Self.pages[index], progress: progress)
    }

    private func finishWithCat() {
        guard !isFinishing else { return }
        guard CatProfile.cleaned(catName) != nil else {
            view?.showNameRequired(announcement: Self.nameRequiredAnnouncement)
            return
        }
        isFinishing = true
        interactor?.saveCat(name: catName, face: currentFace)
        interactor?.completeOnboarding()
        guard let view else {
            router?.finish()
            return
        }
        view.showFinishCelebration { [weak self] in self?.router?.finish() }
    }

    private func finishWithoutCat() {
        guard !isFinishing else { return }
        isFinishing = true
        interactor?.completeOnboarding()
        router?.finish()
    }
}
