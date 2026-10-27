//
//  ProfilesViewController+Alerts.swift
//  pawpaw
//

import UIKit

extension ProfilesViewController {
    func showAddAlert() {
        let alert = UIAlertController(title: "Add a cat", message: "What is your cat called?", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Name" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self, weak alert] _ in
            self?.presenter?.didAddProfile(name: alert?.textFields?.first?.text ?? "")
        })
        present(alert, animated: true)
    }

    func showEditAlert(for row: ProfileRow) {
        let alert = UIAlertController(title: "Edit cat", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Name" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self, weak alert] _ in
            self?.presenter?.didRenameProfile(id: row.id, name: alert?.textFields?.first?.text ?? "")
        })
        if canDelete {
            alert.addAction(UIAlertAction(title: "Delete…", style: .destructive) { [weak self] _ in
                self?.showDeleteAlert(for: row)
            })
        }
        present(alert, animated: true)
    }

    /// Deleting erases a cat's history, so it asks a second time.
    func showDeleteAlert(for row: ProfileRow) {
        let alert = UIAlertController(
            title: "Delete \(row.title)?",
            message: "This erases this cat's best scores and play stats.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.presenter?.didConfirmDelete(id: row.id)
        })
        present(alert, animated: true)
    }
}
