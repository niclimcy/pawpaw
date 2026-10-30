//
//  ProfilesViewController+Builders.swift
//  pawpaw
//

import UIKit

extension ProfilesViewController {
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
        config.titleTextAttributesTransformer = Theme.fontTransformer(size: 22, weight: .bold)
        config.subtitleTextAttributesTransformer = Theme.fontTransformer(size: 14, weight: .semibold)
        let select = UIButton(configuration: config)
        select.contentHorizontalAlignment = .leading
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
        let button = Theme.filledButton(
            title: "Add a cat",
            image: "plus",
            fontSize: 18,
            background: Theme.panel,
            foreground: Theme.text,
            insets: NSDirectionalEdgeInsets(top: 14, leading: 28, bottom: 14, trailing: 28)
        )
        button.accessibilityIdentifier = "addCatButton"
        button.addAction(UIAction { [weak self] _ in self?.showAddCard() }, for: .touchUpInside)
        return button
    }

    func makeBackButton() -> UIButton {
        let button = Theme.filledButton(title: "Back")
        button.accessibilityIdentifier = "profilesBackButton"
        button.addAction(UIAction { [weak self] _ in self?.presenter?.didTapBack() }, for: .touchUpInside)
        return button
    }
}
