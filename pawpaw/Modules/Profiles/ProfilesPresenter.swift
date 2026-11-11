//
//  ProfilesPresenter.swift
//  pawpaw
//

import Foundation

final class ProfilesPresenter: ProfilesPresenterProtocol, ProfilesInteractorOutputProtocol {
    // TODO: To remove after swift bug is resolved.
    nonisolated deinit {}

    weak var view: ProfilesViewProtocol?
    var interactor: ProfilesInteractorInputProtocol?
    var router: ProfilesRouterProtocol?

    static let addTitle = "Add a cat"
    static let editTitle = "Edit cat"
    static let critterHint =
        "Keep at least one critter that isn't a fish, a lizard or the laser on. Fish only swim in the pond, lizards only live on grass, and the laser can't be caught after a round."

    private struct Editing {
        /// `nil` when adding.
        let id: UUID?
        var disabledKinds: Set<TargetKind>
    }

    private var rows: [ProfileRow] = []
    private var canDelete = false
    private var editing: Editing?

    // MARK: ProfilesPresenterProtocol
    func viewDidLoad() {
        interactor?.fetchTheme()
    }

    func viewWillAppear() {
        interactor?.fetchProfiles()
    }

    func didTapBack() {
        router?.navigateBack(from: view)
    }

    func didSelectProfile(id: UUID) {
        interactor?.selectProfile(id: id)
    }

    func didTapAdd() {
        let usedFaces = Set(rows.map(\.face))
        let face = CatFace.allCases.first { !usedFaces.contains($0) } ?? .orange
        editing = Editing(id: nil, disabledKinds: [])
        view?.showEditor(
            ProfileEditorContent(
                title: Self.addTitle, name: "", face: face, disabledKinds: [], isAdding: true,
                canDelete: false))
    }

    func didTapEdit(id: UUID) {
        guard let row = rows.first(where: { $0.id == id }) else { return }
        editing = Editing(id: id, disabledKinds: row.disabledKinds)
        view?.showEditor(
            ProfileEditorContent(
                title: Self.editTitle, name: row.name, face: row.face,
                disabledKinds: row.disabledKinds, isAdding: false, canDelete: canDelete))
    }

    /// Turning a critter on always works; turning one off must leave a playable set.
    func didToggleCritter(_ kind: TargetKind) {
        guard var current = editing else { return }
        var updated = current.disabledKinds
        if updated.remove(kind) == nil {
            updated.insert(kind)
            guard CatProfile.isPlayable(disabledKinds: updated) else {
                view?.showCritterRefused(kind, hint: Self.critterHint)
                return
            }
        }
        current.disabledKinds = updated
        editing = current
        view?.showCritters(disabledKinds: updated)
    }

    func didTapSave(name: String, face: CatFace) {
        guard let current = editing else { return }
        // An empty name is only invalid when adding; editing keeps the old name.
        if current.id == nil, CatProfile.cleaned(name) == nil {
            view?.showNameRequired()
            return
        }
        editing = nil
        view?.hideEditor()
        if let id = current.id {
            interactor?.updateProfile(
                id: id, name: name, face: face, disabledKinds: current.disabledKinds)
        } else {
            interactor?.addProfile(name: name, face: face, disabledKinds: current.disabledKinds)
        }
    }

    func didTapCancel() {
        editing = nil
        view?.hideEditor()
    }

    func didConfirmDelete() {
        guard let id = editing?.id else { return }
        editing = nil
        view?.hideEditor()
        interactor?.deleteProfile(id: id)
    }

    // MARK: ProfilesInteractorOutputProtocol
    func didFetchTheme(_ theme: PlayfieldTheme) {
        view?.showTheme(theme)
    }

    func didFetchProfiles(_ entries: [ProfileEntry], activeID: UUID) {
        rows = entries.map { entry in
            ProfileRow(
                id: entry.profile.id,
                name: entry.profile.name,
                face: entry.profile.face,
                subtitle: entry.favorite.map(CatProfile.lovesText) ?? "No favorite yet",
                isActive: entry.profile.id == activeID,
                disabledKinds: entry.profile.disabledKinds
            )
        }
        canDelete = entries.count > 1
        view?.showProfiles(rows)
    }
}
