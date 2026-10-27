//
//  ProfilesViewController+Builders.swift
//  pawpaw
//

import UIKit

extension ProfilesViewController {
    /// A cat's button (tap to play as that cat) with a pencil beside it to rename or delete.
    func makeRow(_ row: ProfileRow) -> UIView {
        var config = row.isActive ? UIButton.Configuration.filled() : UIButton.Configuration.tinted()
        config.title = row.isActive ? "\(row.name)  ✓" : row.name
        config.subtitle = row.subtitle
        config.image = row.face.image(side: Theme.scaled(52))
        config.imagePadding = 14
        config.baseBackgroundColor = row.isActive ? Theme.accent : Theme.text
        config.baseForegroundColor = row.isActive ? .white : Theme.text
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        config.titleAlignment = .leading
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.roundedFont(size: Theme.scaled(22), weight: .bold)
            return outgoing
        }
        config.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.roundedFont(size: Theme.scaled(14), weight: .semibold)
            return outgoing
        }
        let select = UIButton(configuration: config)
        select.contentHorizontalAlignment = .leading
        // The cat takes all the spare width; the pencil stays small.
        select.setContentHuggingPriority(.defaultLow, for: .horizontal)
        select.heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.minimumTapSize).isActive = true
        select.accessibilityIdentifier = "profileRow"
        select.accessibilityLabel = "\(row.name), \(row.face.title). \(row.subtitle)"
        select.accessibilityTraits = row.isActive ? [.button, .selected] : .button
        select.addAction(UIAction { [weak self] _ in self?.presenter?.didSelectProfile(id: row.id) }, for: .touchUpInside)

        var editConfig = UIButton.Configuration.plain()
        editConfig.image = UIImage(systemName: "pencil")
        editConfig.baseForegroundColor = Theme.text
        editConfig.contentInsets = .zero
        let edit = UIButton(configuration: editConfig)
        edit.setContentHuggingPriority(.required, for: .horizontal)
        edit.setContentCompressionResistancePriority(.required, for: .horizontal)
        edit.widthAnchor.constraint(equalToConstant: Theme.minimumTapSize).isActive = true
        edit.accessibilityLabel = "Edit \(row.name)"
        edit.addAction(UIAction { [weak self] _ in self?.showEditCard(for: row) }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [select, edit])
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.spacing = 4
        return stack
    }

    func makeAddButton() -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = "Add a cat"
        config.image = UIImage(systemName: "plus")
        config.imagePadding = 6
        config.baseBackgroundColor = Theme.panel
        config.baseForegroundColor = Theme.text
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 28, bottom: 14, trailing: 28)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.roundedFont(size: Theme.scaled(18), weight: .bold)
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.minimumTapSize).isActive = true
        button.accessibilityIdentifier = "addCatButton"
        button.addAction(UIAction { [weak self] _ in self?.showAddCard() }, for: .touchUpInside)
        return button
    }

    func makeBackButton() -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = "Back"
        config.baseBackgroundColor = Theme.accent
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 36, bottom: 14, trailing: 36)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.roundedFont(size: Theme.scaled(20), weight: .bold)
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.minimumTapSize).isActive = true
        button.accessibilityIdentifier = "profilesBackButton"
        button.addAction(UIAction { [weak self] _ in self?.presenter?.didTapBack() }, for: .touchUpInside)
        return button
    }
}
