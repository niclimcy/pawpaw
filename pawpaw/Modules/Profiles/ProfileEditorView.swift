//
//  ProfileEditorView.swift
//  pawpaw
//

import UIKit

/// A wood-styled card over the profiles list to add a cat or edit one. It replaces system alerts,
/// so the game's look stays the same all the way through.
final class ProfileEditorView: UIView, UITextFieldDelegate {
    var onSave: ((String, CatFace) -> Void)?
    var onDelete: (() -> Void)?

    let titleLabel = UILabel()
    let nameField = UITextField()
    /// Replaced by the real button when the card is built.
    var deleteButton = UIButton(type: .system)
    var faceButtons: [CatFace: UIButton] = [:]
    var selectedFace: CatFace = .orange
    private var isAdding = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }

    // MARK: Showing
    func present(adding: Bool, name: String, face: CatFace, canDelete: Bool) {
        isAdding = adding
        titleLabel.text = adding ? "Add a cat" : "Edit cat"
        nameField.text = name
        deleteButton.isHidden = adding || !canDelete
        select(face)
        isHidden = false
        alpha = 0
        UIView.animate(withDuration: 0.2) { self.alpha = 1 }
        if adding { nameField.becomeFirstResponder() }
    }

    func dismiss() {
        nameField.resignFirstResponder()
        UIView.animate(withDuration: 0.2, animations: { self.alpha = 0 }, completion: { _ in
            self.isHidden = true
        })
    }

    func select(_ face: CatFace) {
        selectedFace = face
        for (candidate, button) in faceButtons {
            let isSelected = candidate == face
            button.layer.borderColor = (isSelected ? Theme.gold : UIColor.clear).cgColor
            button.backgroundColor = isSelected
                ? Theme.accent.withAlphaComponent(0.35)
                : Theme.background.withAlphaComponent(0.5)
            button.accessibilityTraits = isSelected ? [.button, .selected] : .button
        }
    }

    // MARK: Actions
    @objc func saveTapped() {
        let name = nameField.text ?? ""
        // A new cat needs a name; an empty name on an existing cat keeps the old one.
        if isAdding, CatProfile.cleaned(name) == nil {
            shakeNameField()
            nameField.becomeFirstResponder()
            return
        }
        dismiss()
        onSave?(name, selectedFace)
    }

    @objc func cancelTapped() {
        dismiss()
    }

    /// `.began` fires only after the full hold, so a paw can't delete a cat by accident.
    @objc func deleteHeld(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
        onDelete?()
    }

    private func shakeNameField() {
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.values = [0, -8, 8, -5, 5, 0]
        shake.duration = 0.3
        nameField.layer.add(shake, forKey: "shake")
    }

    // MARK: UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let current = textField.text ?? ""
        guard let swiftRange = Range(range, in: current) else { return true }
        return current.replacingCharacters(in: swiftRange, with: string).count <= CatProfile.maxNameLength
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
