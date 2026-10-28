//
//  ProfilesPresenter.swift
//  pawpaw
//

import Foundation

final class ProfilesPresenter: ProfilesPresenterProtocol, ProfilesInteractorOutputProtocol {
    weak var view: ProfilesViewProtocol?
    var interactor: ProfilesInteractorInputProtocol?
    var router: ProfilesRouterProtocol?

    // MARK: ProfilesPresenterProtocol
    func viewWillAppear() {
        interactor?.fetchProfiles()
    }

    func didTapBack() {
        router?.navigateBack(from: view)
    }

    func didSelectProfile(id: UUID) {
        interactor?.selectProfile(id: id)
    }

    func didAddProfile(name: String, face: CatFace, disabledKinds: Set<TargetKind>) {
        interactor?.addProfile(name: name, face: face, disabledKinds: disabledKinds)
    }

    func didUpdateProfile(id: UUID, name: String, face: CatFace, disabledKinds: Set<TargetKind>) {
        interactor?.updateProfile(id: id, name: name, face: face, disabledKinds: disabledKinds)
    }

    func didConfirmDelete(id: UUID) {
        interactor?.deleteProfile(id: id)
    }

    // MARK: ProfilesInteractorOutputProtocol
    func didFetchProfiles(_ entries: [ProfileEntry], activeID: UUID) {
        let rows = entries.map { entry in
            ProfileRow(
                id: entry.profile.id,
                name: entry.profile.name,
                face: entry.profile.face,
                subtitle: entry.favorite.map { "Loves \($0.pluralName)" } ?? "No favorite yet",
                isActive: entry.profile.id == activeID,
                disabledKinds: entry.profile.disabledKinds
            )
        }
        view?.showProfiles(rows, canDelete: entries.count > 1)
    }
}
