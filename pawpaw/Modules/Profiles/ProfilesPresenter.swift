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

    func didAddProfile(name: String) {
        interactor?.addProfile(name: name)
    }

    func didRenameProfile(id: UUID, name: String) {
        interactor?.renameProfile(id: id, name: name)
    }

    func didConfirmDelete(id: UUID) {
        interactor?.deleteProfile(id: id)
    }

    // MARK: ProfilesInteractorOutputProtocol
    func didFetchProfiles(_ entries: [ProfileEntry], activeID: UUID) {
        let rows = entries.map { entry in
            ProfileRow(
                id: entry.profile.id,
                title: "\(entry.profile.emoji) \(entry.profile.name)",
                subtitle: entry.favorite.map { "Loves \($0.pluralName)" } ?? "No favorite yet",
                isActive: entry.profile.id == activeID
            )
        }
        view?.showProfiles(rows, canDelete: entries.count > 1)
    }
}
