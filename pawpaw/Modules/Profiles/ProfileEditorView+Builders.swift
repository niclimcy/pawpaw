//
//  ProfileEditorView+Builders.swift
//  pawpaw
//

import UIKit

extension ProfileEditorView {
    func makeNameField() -> UITextField {
        nameField.font = Theme.roundedFont(size: Theme.scaled(22), weight: .bold)
        nameField.textColor = Theme.text
        nameField.tintColor = Theme.gold
        nameField.textAlignment = .center
        nameField.backgroundColor = Theme.background
        nameField.layer.cornerRadius = 16
        nameField.attributedPlaceholder = NSAttributedString(
            string: "Your cat's name",
            attributes: [.foregroundColor: Theme.text.withAlphaComponent(0.45)]
        )
        nameField.returnKeyType = .done
        nameField.autocapitalizationType = .words
        nameField.delegate = self
        nameField.accessibilityIdentifier = "catNameField"
        nameField.heightAnchor.constraint(greaterThanOrEqualToConstant: max(Theme.minimumTapSize, Theme.scaled(52))).isActive = true
        return nameField
    }

    /// Every cat face in a grid of three. Tap one to wear it.
    func makeFacePicker() -> UIView {
        let faces = CatFace.allCases
        let rows = stride(from: 0, to: faces.count, by: 3).map { start in
            let row = UIStackView(arrangedSubviews: faces[start..<min(start + 3, faces.count)].map(makeFaceButton))
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 10
            return row
        }
        let grid = UIStackView(arrangedSubviews: rows)
        grid.axis = .vertical
        grid.spacing = 10
        return grid
    }

    private func makeFaceButton(_ face: CatFace) -> UIButton {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor.clear.cgColor
        button.accessibilityLabel = face.title
        button.accessibilityIdentifier = "face_\(face.rawValue)"
        button.heightAnchor.constraint(equalTo: button.widthAnchor).isActive = true
        button.addAction(UIAction { [weak self] _ in self?.select(face) }, for: .touchUpInside)

        let picture = UIImageView(image: UIImage(named: face.imageName))
        picture.contentMode = .scaleAspectFit
        picture.isUserInteractionEnabled = false
        picture.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(picture)
        NSLayoutConstraint.activate([
            picture.topAnchor.constraint(equalTo: button.topAnchor, constant: 6),
            picture.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -6),
            picture.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 6),
            picture.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -6)
        ])
        faceButtons[face] = button
        return button
    }

    /// "Critters to play with", then every critter in a grid of four. Tap one to turn it on or off.
    func makeCritterPicker() -> UIView {
        let heading = UILabel()
        heading.text = "Critters to play with"
        heading.font = Theme.roundedFont(size: Theme.scaled(16), weight: .bold)
        heading.textColor = Theme.text
        heading.textAlignment = .center

        let kinds = TargetKind.allCases
        let perRow = 4
        let rows = stride(from: 0, to: kinds.count, by: perRow).map { start -> UIStackView in
            var buttons: [UIView] = kinds[start..<min(start + perRow, kinds.count)].map(makeCritterButton)
            // Keep every button the same size when the last row is short.
            while buttons.count < perRow { buttons.append(UIView()) }
            let row = UIStackView(arrangedSubviews: buttons)
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 8
            return row
        }
        let stack = UIStackView(arrangedSubviews: [heading] + rows)
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }

    private func makeCritterButton(_ kind: TargetKind) -> UIButton {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 2
        button.accessibilityLabel = kind.pluralName.capitalized
        button.accessibilityHint = "Turns \(kind.pluralName) on or off for this cat"
        button.accessibilityIdentifier = "critter_\(kind.rawValue)"
        button.heightAnchor.constraint(equalTo: button.widthAnchor).isActive = true
        button.addAction(UIAction { [weak self] _ in self?.toggle(kind) }, for: .touchUpInside)

        let picture = UIImageView(image: UIImage(named: kind.imageName))
        picture.contentMode = .scaleAspectFit
        picture.isUserInteractionEnabled = false
        picture.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(picture)
        NSLayoutConstraint.activate([
            picture.topAnchor.constraint(equalTo: button.topAnchor, constant: 6),
            picture.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -6),
            picture.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 6),
            picture.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -6)
        ])
        critterButtons[kind] = button
        return button
    }

    func makeSaveButton() -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = "Save"
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
        button.accessibilityIdentifier = "saveCatButton"
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return button
    }

    func makeCancelButton() -> UIButton {
        let button = makePlainButton(title: "Cancel", image: nil)
        button.accessibilityIdentifier = "cancelCatButton"
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return button
    }

    /// Deleting erases a cat's history, so it needs a 1.5 second hold, like leaving the game.
    func makeDeleteButton() -> UIButton {
        let button = makePlainButton(title: "Hold to delete this cat", image: "trash")
        button.isHidden = true
        button.accessibilityIdentifier = "deleteCatButton"
        button.accessibilityHint = "Press and hold to erase this cat, its best scores and its stats"
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(deleteHeld(_:)))
        hold.minimumPressDuration = 1.5
        button.addGestureRecognizer(hold)
        deleteButton = button
        return button
    }

    private func makePlainButton(title: String, image: String?) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = image.flatMap { UIImage(systemName: $0) }
        config.imagePadding = 6
        config.baseForegroundColor = Theme.text.withAlphaComponent(0.8)
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.roundedFont(size: Theme.scaled(16), weight: .bold)
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.minimumTapSize).isActive = true
        return button
    }
}
