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

// MARK: - View
protocol OnboardingViewProtocol: AnyObject {
    var presenter: OnboardingPresenterProtocol? { get set }
    /// Sizes the card for the longest text so its height stays fixed.
    func reserveSpace(for texts: [OnboardingText])
    func showPage(_ page: OnboardingPage, index: Int, count: Int)
    /// `celebrates` is false for hints.
    func showPracticeFeedback(_ text: OnboardingText, celebrates: Bool)
    /// The last step, after the intro pages.
    func showCatSetup(face: CatFace, title: String, index: Int, count: Int)
    func updateCatSetupTitle(_ title: String)
    func showNameRequired()
    func showFinishCelebration(completion: @escaping () -> Void)
}

// MARK: - Presenter
protocol OnboardingPresenterProtocol: AnyObject {
    var view: OnboardingViewProtocol? { get set }
    var interactor: OnboardingInteractorInputProtocol? { get set }
    var router: OnboardingRouterProtocol? { get set }

    func viewDidLoad()
    func didTapNext()
    func didTapBack()
    func didTapSkip()
    func didTapDone(name: String, face: CatFace)
    func didSkipCatSetup()

    // Practice
    func didCatchPracticeCritter()
    func didTapHousePractice()
    func didCompleteHoldPractice()
    func didChangeCatName(_ name: String)
}

// MARK: - Interactor
protocol OnboardingInteractorInputProtocol: AnyObject {
    var activeProfile: CatProfile { get }
    func saveCat(name: String, face: CatFace)
    func completeOnboarding()
}

// MARK: - Router
protocol OnboardingRouterProtocol: AnyObject {
    static func createModule(onFinish: @escaping () -> Void) -> UIViewController
    func finish()
}
