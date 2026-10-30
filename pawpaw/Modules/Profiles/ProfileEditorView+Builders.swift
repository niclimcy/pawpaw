//
//  ProfileEditorView+Builders.swift
//  pawpaw
//

import UIKit

extension ProfileEditorView {
    func makeNameField() -> UITextField {
        nameField.font = Theme.roundedFont(size: Theme.scaled(22), weight: .bold)
        nameField.adjustsFontForContentSizeCategory = true
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

    func makeCritterPicker() -> UIView {
        let heading = UILabel()
        heading.text = "Critters to play with"
        heading.font = Theme.roundedFont(size: Theme.scaled(16), weight: .bold)
        heading.adjustsFontForContentSizeCategory = true
        heading.textColor = Theme.text
        heading.textAlignment = .center
        heading.numberOfLines = 0
        heading.accessibilityTraits = .header

        critterHintLabel.text = "Keep at least one critter that isn't a fish on. Fish only swim in the pond."
        critterHintLabel.font = Theme.roundedFont(size: Theme.scaled(14), weight: .semibold)
        critterHintLabel.adjustsFontForContentSizeCategory = true
        critterHintLabel.textColor = Theme.gold
        critterHintLabel.textAlignment = .center
        critterHintLabel.numberOfLines = 0
        critterHintLabel.isHidden = true

        let kinds = TargetKind.allCases
        let perRow = 4
        let rows = stride(from: 0, to: kinds.count, by: perRow).map { start -> UIStackView in
            var buttons: [UIView] = kinds[start..<min(start + perRow, kinds.count)].map(makeCritterButton)
            // Pad a short last row so buttons stay equal width.
            while buttons.count < perRow { buttons.append(UIView()) }
            let row = UIStackView(arrangedSubviews: buttons)
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 8
            return row
        }
        let stack = UIStackView(arrangedSubviews: [heading] + rows + [critterHintLabel])
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
        let button = Theme.filledButton(title: "Save")
        button.accessibilityIdentifier = "saveCatButton"
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return button
    }

    func makeCancelButton() -> UIButton {
        let button = Theme.plainButton(title: "Cancel")
        button.accessibilityIdentifier = "cancelCatButton"
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return button
    }

    func makeDeleteButton() -> UIButton {
        let button = Theme.plainButton(title: "Hold to delete this cat", image: "trash")
        button.isHidden = true
        button.accessibilityIdentifier = "deleteCatButton"
        button.accessibilityHint = "Press and hold to erase this cat, its best scores and its stats"
        button.addGestureRecognizer(UILongPressGestureRecognizer.holdToConfirm(self, #selector(deleteHeld(_:))))
        deleteButton = button
        return button
    }
}
