//
//  OnboardingProtocols.swift
//  pawpaw
//

import UIKit

struct OnboardingPage: Equatable {
    let title: String
    let body: String
    /// Asset names shown in a row above the title.
    let imageNames: [String]
    /// SF Symbol shown instead of the images.
    var symbolName: String?
}

// MARK: - View
protocol OnboardingViewProtocol: AnyObject {
    var presenter: OnboardingPresenterProtocol? { get set }
    /// Sizes the card for the longest page so it keeps one height between pages.
    func reserveSpace(for pages: [OnboardingPage])
    func showPage(_ page: OnboardingPage, index: Int, count: Int)
    /// The last step, after the intro pages.
    func showCatSetup(face: CatFace, index: Int, count: Int)
    func showNameRequired()
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
