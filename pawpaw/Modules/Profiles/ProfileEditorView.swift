//
//  ProfileEditorView.swift
//  pawpaw
//

import UIKit

/// A wood-styled card over the profiles list to add a cat or edit one. It replaces system alerts,
/// so the game's look stays the same all the way through.
final class ProfileEditorView: UIView, UITextFieldDelegate {
    /// Name, face and the critters turned off for this cat.
    var onSave: ((String, CatFace, Set<TargetKind>) -> Void)?
    var onDelete: (() -> Void)?

    let titleLabel = UILabel()
    let nameField = UITextField()
    /// Explains why the last critter for every background can't be turned off. Hidden until that happens.
    let critterHintLabel = UILabel()
    /// Replaced by the real button when the card is built.
    var deleteButton = UIButton(type: .system)
    var faceButtons: [CatFace: UIButton] = [:]
    var selectedFace: CatFace = .orange
    var critterButtons: [TargetKind: UIButton] = [:]
    /// Critters this cat won't see. Tapping a critter in the card toggles it.
    var disabledKinds: Set<TargetKind> = []
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
    func present(adding: Bool, name: String, face: CatFace, disabledKinds: Set<TargetKind> = [], canDelete: Bool) {
        isAdding = adding
        titleLabel.text = adding ? "Add a cat" : "Edit cat"
        nameField.text = name
        deleteButton.isHidden = adding || !canDelete
        select(face)
        self.disabledKinds = disabledKinds
        critterHintLabel.isHidden = true
        refreshCritters()
        isHidden = false
        alpha = 0
        UIView.animate(withDuration: 0.2) { self.alpha = 1 }
        if adding { nameField.becomeFirstResponder() }
        // VoiceOver stays inside the card and starts at its title.
        UIAccessibility.post(notification: .screenChanged, argument: titleLabel)
    }

    func dismiss() {
        nameField.resignFirstResponder()
        UIView.animate(withDuration: 0.2, animations: { self.alpha = 0 }, completion: { _ in
            self.isHidden = true
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        })
    }

    /// Escape (the two-finger scrub) closes the card, like Cancel.
    override func accessibilityPerformEscape() -> Bool {
        cancelTapped()
        return true
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

    /// Turns a critter on or off for this cat. The last critter that can play on every background can't be
    /// turned off (fish only live in the pond), so the shake comes with a short explanation.
    func toggle(_ kind: TargetKind) {
        guard let updated = Self.toggled(kind, in: disabledKinds) else {
            shake(critterButtons[kind])
            critterHintLabel.isHidden = false
            UIAccessibility.post(notification: .announcement, argument: critterHintLabel.text)
            return
        }
        disabledKinds = updated
        critterHintLabel.isHidden = true
        refreshCritters()
    }

    /// `disabled` with `kind` switched on or off, or `nil` when that would leave a background with nothing to play.
    /// Turning a critter back on is always allowed.
    static func toggled(_ kind: TargetKind, in disabled: Set<TargetKind>) -> Set<TargetKind>? {
        var updated = disabled
        if updated.remove(kind) != nil { return updated }
        updated.insert(kind)
        return CatProfile.isPlayable(disabledKinds: updated) ? updated : nil
    }

    private func refreshCritters() {
        for (kind, button) in critterButtons {
            let isOn = !disabledKinds.contains(kind)
            button.alpha = isOn ? 1 : 0.35
            button.layer.borderColor = (isOn ? Theme.gold : UIColor.clear).cgColor
            button.backgroundColor = isOn
                ? Theme.accent.withAlphaComponent(0.25)
                : Theme.background.withAlphaComponent(0.5)
            button.accessibilityValue = isOn ? "On" : "Off"
            button.accessibilityTraits = isOn ? [.button, .selected] : .button
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
        onSave?(name, selectedFace, disabledKinds)
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
        shake(nameField)
    }

    private func shake(_ view: UIView?) {
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.values = [0, -8, 8, -5, 5, 0]
        shake.duration = 0.3
        view?.layer.add(shake, forKey: "shake")
    }

    // MARK: UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let current = textField.text ?? ""
        guard let swiftRange = Range(range, in: current) else { return true }
        let proposed = current.replacingCharacters(in: swiftRange, with: string)
        if proposed.count <= CatProfile.maxNameLength { return true }
        // Too long, usually a paste: keep as much of the new text as fits instead of dropping all of it.
        let room = CatProfile.maxNameLength - (current.count - current[swiftRange].count)
        guard room > 0 else { return false }
        let kept = String(string.prefix(room))
        textField.text = current.replacingCharacters(in: swiftRange, with: kept)
        let caretOffset = current.distance(from: current.startIndex, to: swiftRange.lowerBound) + kept.count
        if let caret = textField.position(from: textField.beginningOfDocument, offset: caretOffset) {
            textField.selectedTextRange = textField.textRange(from: caret, to: caret)
        }
        return false
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
