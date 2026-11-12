//
//  ProfileEditorView.swift
//  pawpaw
//

import UIKit

final class ProfileEditorView: UIView, UITextFieldDelegate {
    // TODO: To remove after swift bug is resolved.
    nonisolated deinit {}

    var onSave: ((String, CatFace) -> Void)?
    var onCancel: (() -> Void)?
    var onDelete: (() -> Void)?
    var onToggleCritter: ((TargetKind) -> Void)?

    let titleLabel = UILabel()
    let nameField = CatNameField()
    /// Fills the card's width, shrinking down to tap size when the card needs the room.
    let facePicker = CatFacePicker(perRow: 3, minSide: Theme.minimumTapSize)
    let critterHintLabel = UILabel()
    /// Replaced by the real button in `build()`.
    var deleteButton = UIButton(type: .system)
    var critterButtons: [TargetKind: UIButton] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }

    // MARK: Showing
    func present(_ content: ProfileEditorContent) {
        titleLabel.text = content.title
        nameField.text = content.name
        deleteButton.isHidden = !content.canDelete
        facePicker.select(content.face)
        showCritters(disabledKinds: content.disabledKinds)
        isHidden = false
        alpha = 0
        UIView.animate(withDuration: 0.2) { self.alpha = 1 }
        if content.isAdding { nameField.becomeFirstResponder() }
        UIAccessibility.post(notification: .screenChanged, argument: titleLabel)
    }

    func dismiss() {
        nameField.resignFirstResponder()
        UIView.animate(
            withDuration: 0.2, animations: { self.alpha = 0 },
            completion: { _ in
                self.isHidden = true
                UIAccessibility.post(notification: .screenChanged, argument: nil)
            })
    }

    override func accessibilityPerformEscape() -> Bool {
        cancelTapped()
        return true
    }

    func toggle(_ kind: TargetKind) {
        onToggleCritter?(kind)
    }

    func showCritters(disabledKinds: Set<TargetKind>) {
        critterHintLabel.isHidden = true
        for (kind, button) in critterButtons {
            let isOn = !disabledKinds.contains(kind)
            button.alpha = isOn ? 1 : 0.35
            button.layer.borderColor = (isOn ? Theme.gold : UIColor.clear).cgColor
            button.backgroundColor =
                isOn ? Theme.selectedChoiceFill : Theme.unselectedChoiceFill
            button.accessibilityValue = isOn ? "On" : "Off"
            // Just `.button`: `.selected` would make VoiceOver say the state twice.
            button.accessibilityTraits = .button
        }
    }

    func showCritterRefused(_ kind: TargetKind, hint: String) {
        critterButtons[kind]?.shakeHorizontally()
        critterHintLabel.text = hint
        critterHintLabel.isHidden = false
        UIAccessibility.post(notification: .announcement, argument: hint)
    }

    func showNameRequired() {
        nameField.shakeHorizontally()
        nameField.becomeFirstResponder()
    }

    // MARK: Actions
    @objc func saveTapped() {
        onSave?(nameField.text ?? "", facePicker.selectedFace)
    }

    @objc func cancelTapped() {
        onCancel?()
    }

    @objc func deleteHeld(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        confirmDelete()
    }

    func confirmDelete() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onDelete?()
    }

    // MARK: UITextFieldDelegate
    func textField(
        _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        nameField.shouldChangeCharacters(in: range, replacementString: string)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
