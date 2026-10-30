//
//  CatNameField.swift
//  pawpaw
//

import UIKit

/// A themed name field. The delegate should forward
/// `textField(_:shouldChangeCharactersIn:replacementString:)` to `shouldChangeCharacters`.
final class CatNameField: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        font = Theme.roundedFont(size: Theme.scaled(22), weight: .bold)
        adjustsFontForContentSizeCategory = true
        textColor = Theme.text
        tintColor = Theme.gold
        textAlignment = .center
        backgroundColor = Theme.background
        layer.cornerRadius = 16
        attributedPlaceholder = NSAttributedString(
            string: "Your cat's name",
            attributes: [.foregroundColor: Theme.text.withAlphaComponent(0.45)]
        )
        returnKeyType = .done
        autocapitalizationType = .words
        autocorrectionType = .no
        accessibilityIdentifier = "catNameField"
        heightAnchor.constraint(greaterThanOrEqualToConstant: max(Theme.minimumTapSize, Theme.scaled(52))).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Caps the name at `CatProfile.maxNameLength`.
    func shouldChangeCharacters(in range: NSRange, replacementString string: String) -> Bool {
        let current = text ?? ""
        guard let swiftRange = Range(range, in: current) else { return true }
        let proposed = current.replacingCharacters(in: swiftRange, with: string)
        if proposed.count <= CatProfile.maxNameLength { return true }
        // Too long (usually a paste): insert as much as fits rather than rejecting it all.
        let room = CatProfile.maxNameLength - (current.count - current[swiftRange].count)
        guard room > 0 else { return false }
        let kept = String(string.prefix(room))
        text = current.replacingCharacters(in: swiftRange, with: kept)
        let caretOffset = current.distance(from: current.startIndex, to: swiftRange.lowerBound) + kept.count
        if let caret = position(from: beginningOfDocument, offset: caretOffset) {
            selectedTextRange = textRange(from: caret, to: caret)
        }
        return false
    }
}
