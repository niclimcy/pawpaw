//
//  ProfilesProtocols.swift
//  pawpaw
//

import UIKit

struct ProfileEntry: Equatable {
    let profile: CatProfile
    let favorite: TargetKind?
}

struct ProfileRow: Equatable {
    let id: UUID
    let name: String
    let face: CatFace
    let subtitle: String
    let isActive: Bool
    var disabledKinds: Set<TargetKind> = []
}

/// Everything the add/edit card shows when it opens.
struct ProfileEditorContent: Equatable {
    let title: String
    let name: String
    let face: CatFace
    let disabledKinds: Set<TargetKind>
    let isAdding: Bool
    let canDelete: Bool
}

// MARK: - View
protocol ProfilesViewProtocol: AnyObject {
    var presenter: ProfilesPresenterProtocol? { get set }
    func showTheme(_ theme: PlayfieldTheme)
    func showProfiles(_ rows: [ProfileRow])
    func showEditor(_ content: ProfileEditorContent)
    func hideEditor()
    func showCritters(disabledKinds: Set<TargetKind>)
    /// `hint` explains why `kind` can't be switched off.
    func showCritterRefused(_ kind: TargetKind, hint: String)
    func showNameRequired()
}

// MARK: - Presenter
protocol ProfilesPresenterProtocol: AnyObject {
    var view: ProfilesViewProtocol? { get set }
    var interactor: ProfilesInteractorInputProtocol? { get set }
    var router: ProfilesRouterProtocol? { get set }

    func viewDidLoad()
    func viewWillAppear()
    func didTapBack()
    func didSelectProfile(id: UUID)
    func didTapAdd()
    func didTapEdit(id: UUID)
    func didToggleCritter(_ kind: TargetKind)
    /// Adds or updates the cat being edited; `name` is the raw field text.
    func didTapSave(name: String, face: CatFace)
    func didTapCancel()
    func didConfirmDelete()
}

// MARK: - Interactor
protocol ProfilesInteractorInputProtocol: AnyObject {
    var presenter: ProfilesInteractorOutputProtocol? { get set }
    func fetchTheme()
    func fetchProfiles()
    func selectProfile(id: UUID)
    func addProfile(name: String, face: CatFace, disabledKinds: Set<TargetKind>)
    func updateProfile(id: UUID, name: String, face: CatFace, disabledKinds: Set<TargetKind>)
    func deleteProfile(id: UUID)
}

protocol ProfilesInteractorOutputProtocol: AnyObject {
    func didFetchTheme(_ theme: PlayfieldTheme)
    func didFetchProfiles(_ entries: [ProfileEntry], activeID: UUID)
}

// MARK: - Router
protocol ProfilesRouterProtocol: AnyObject {
    static func createModule() -> UIViewController
    func navigateBack(from view: ProfilesViewProtocol?)
}
