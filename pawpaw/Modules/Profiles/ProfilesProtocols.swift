//
//  ProfilesProtocols.swift
//  pawpaw
//

import UIKit

/// A cat and the critter it catches most, as the interactor reads them.
struct ProfileEntry: Equatable {
    let profile: CatProfile
    let favorite: TargetKind?
}

/// One line of the profiles list, already formatted as text.
struct ProfileRow: Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let isActive: Bool
}

// MARK: - View
protocol ProfilesViewProtocol: AnyObject {
    var presenter: ProfilesPresenterProtocol? { get set }
    /// `canDelete` is false when only one cat is left.
    func showProfiles(_ rows: [ProfileRow], canDelete: Bool)
}

// MARK: - Presenter
protocol ProfilesPresenterProtocol: AnyObject {
    var view: ProfilesViewProtocol? { get set }
    var interactor: ProfilesInteractorInputProtocol? { get set }
    var router: ProfilesRouterProtocol? { get set }

    func viewWillAppear()
    func didTapBack()
    func didSelectProfile(id: UUID)
    func didAddProfile(name: String)
    func didRenameProfile(id: UUID, name: String)
    func didConfirmDelete(id: UUID)
}

// MARK: - Interactor
protocol ProfilesInteractorInputProtocol: AnyObject {
    var presenter: ProfilesInteractorOutputProtocol? { get set }
    func fetchProfiles()
    func selectProfile(id: UUID)
    func addProfile(name: String)
    func renameProfile(id: UUID, name: String)
    func deleteProfile(id: UUID)
}

protocol ProfilesInteractorOutputProtocol: AnyObject {
    func didFetchProfiles(_ entries: [ProfileEntry], activeID: UUID)
}

// MARK: - Router
protocol ProfilesRouterProtocol: AnyObject {
    static func createModule() -> UIViewController
    func navigateBack(from view: ProfilesViewProtocol?)
}
