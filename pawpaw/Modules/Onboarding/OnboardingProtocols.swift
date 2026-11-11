//
//  OnboardingProtocols.swift
//  pawpaw
//

import UIKit

struct OnboardingText: Equatable {
    let title: String
    let body: String
}

enum OnboardingInteraction: Equatable {
    case catchCritter
    case countdown
    case holdToLeave
}

struct OnboardingPage: Equatable {
    let title: String
    let body: String
    let interaction: OnboardingInteraction

    var text: OnboardingText {
        OnboardingText(title: title, body: body)
    }
}

struct OnboardingProgress: Equatable {
    let index: Int
    let count: Int
    let stepLabel: String
    let nextTitle: String
    /// False on the cat setup, which only finishes from its button.
    let canSwipeForward: Bool

    var canGoBack: Bool { index > 0 }
}

/// The last step, after the intro pages.
struct OnboardingCatSetup: Equatable {
    let face: CatFace
    let title: String
    let body: String
}

struct OnboardingStaticText: Equatable {
    let skipTitle: String
    let skipHint: String
    let skipAction: String
    let holdPrompt: String
    let countdownDescription: String
}

// MARK: - View
protocol OnboardingViewProtocol: AnyObject {
    var presenter: OnboardingPresenterProtocol? { get set }
    func showStaticText(_ text: OnboardingStaticText)
    /// Sizes the card for the longest text so its height stays fixed.
    func reserveSpace(for texts: [OnboardingText])
    func showPage(_ page: OnboardingPage, progress: OnboardingProgress)
    /// `celebrates` is false for hints.
    func showPracticeFeedback(_ text: OnboardingText, celebrates: Bool)
    func showCatSetup(_ setup: OnboardingCatSetup, progress: OnboardingProgress)
    func updateCatSetupTitle(_ title: String)
    func showNameRequired(announcement: String)
    func showFinishCelebration(completion: @escaping () -> Void)
}

// MARK: - Presenter
protocol OnboardingPresenterProtocol: AnyObject {
    var view: OnboardingViewProtocol? { get set }
    var interactor: OnboardingInteractorInputProtocol? { get set }
    var router: OnboardingRouterProtocol? { get set }

    func viewDidLoad()
    /// Moves on a page; on the cat setup, saves the cat and finishes.
    func didTapNext()
    func didTapBack()
    /// Skips the intro pages; on the cat setup, finishes without saving.
    func didTapSkip()
    func didChangeCatName(_ name: String)
    func didSelectFace(_ face: CatFace)

    // Practice
    func nextPracticeTarget() -> GameTarget?
    func didCatchPracticeCritter()
    func didTapHousePractice()
    func didCompleteHoldPractice()
}

// MARK: - Interactor
protocol OnboardingInteractorInputProtocol: AnyObject {
    var activeProfile: CatProfile { get }
    func saveCat(name: String, face: CatFace)
    func completeOnboarding()
    func makePracticeTarget(kind: TargetKind) -> GameTarget
}

// MARK: - Router
protocol OnboardingRouterProtocol: AnyObject {
    static func createModule(onFinish: @escaping () -> Void) -> UIViewController
    func finish()
}
