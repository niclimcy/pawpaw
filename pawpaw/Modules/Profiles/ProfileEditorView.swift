//
//  ProfileEditorView.swift
//  pawpaw
//

import UIKit

final class ProfileEditorView: UIView, UITextFieldDelegate {
    /// Name, face and disabled critters.
    var onSave: ((String, CatFace, Set<TargetKind>) -> Void)?
    var onDelete: (() -> Void)?

    let titleLabel = UILabel()
    let nameField = UITextField()
    let critterHintLabel = UILabel()
    /// Replaced by the real button in `build()`.
    var deleteButton = UIButton(type: .system)
    var faceButtons: [CatFace: UIButton] = [:]
    var selectedFace: CatFace = .orange
    var critterButtons: [TargetKind: UIButton] = [:]
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
        UIAccessibility.post(notification: .screenChanged, argument: titleLabel)
    }

    func dismiss() {
        nameField.resignFirstResponder()
        UIView.animate(withDuration: 0.2, animations: { self.alpha = 0 }, completion: { _ in
            self.isHidden = true
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        })
    }

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

    /// `nil` when disabling `kind` would leave a theme with nothing to play.
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
        // An empty name is only invalid when adding; editing keeps the old name.
        if isAdding, CatProfile.cleaned(name) == nil {
            shake(nameField)
            nameField.becomeFirstResponder()
            return
        }
        dismiss()
        onSave?(name, selectedFace, disabledKinds)
    }

    @objc func cancelTapped() {
        dismiss()
    }

    @objc func deleteHeld(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
        onDelete?()
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
        // Too long (usually a paste): insert as much as fits rather than rejecting it all.
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
