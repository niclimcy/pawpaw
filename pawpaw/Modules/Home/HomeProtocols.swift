//
//  HomeProtocols.swift
//  pawpaw
//

import UIKit

// MARK: - View
protocol HomeViewProtocol: AnyObject {
    var presenter: HomePresenterProtocol? { get set }
    func showMode(_ mode: SessionMode)
    func showTheme(_ theme: PlayfieldTheme)
    /// `isAvailable` is false for untimed rounds, which never end on their own.
    func showAfterRound(_ afterRound: AfterRoundMode, isAvailable: Bool)
    /// `nil` hides the best score.
    func showHighScore(_ score: Int?)
    func showProfile(name: String, face: CatFace, favorite: String?)
}

// MARK: - Presenter
protocol HomePresenterProtocol: AnyObject {
    var view: HomeViewProtocol? { get set }
    var interactor: HomeInteractorInputProtocol? { get set }
    var router: HomeRouterProtocol? { get set }

    func viewWillAppear()
    func didSelectMode(_ mode: SessionMode)
    func didSelectTheme(_ theme: PlayfieldTheme)
    func didSelectAfterRound(_ afterRound: AfterRoundMode)
    func didTapPlay()
    func didRequestStats()
    func didTapProfile()
}

// MARK: - Interactor
protocol HomeInteractorInputProtocol: AnyObject {
    var presenter: HomeInteractorOutputProtocol? { get set }
    var selectedMode: SessionMode { get }
    func fetchState()
    func selectMode(_ mode: SessionMode)
    func selectTheme(_ theme: PlayfieldTheme)
    func selectAfterRound(_ afterRound: AfterRoundMode)
}

protocol HomeInteractorOutputProtocol: AnyObject {
    func didFetchState(
        mode: SessionMode,
        theme: PlayfieldTheme,
        afterRound: AfterRoundMode,
        highScore: Int?,
        profile: CatProfile,
        favorite: TargetKind?
    )
}

// MARK: - Router
protocol HomeRouterProtocol: AnyObject {
    static func createModule() -> UIViewController
    func navigateToGame(from view: HomeViewProtocol?, mode: SessionMode)
    func navigateToStats(from view: HomeViewProtocol?)
    func navigateToProfiles(from view: HomeViewProtocol?)
}
