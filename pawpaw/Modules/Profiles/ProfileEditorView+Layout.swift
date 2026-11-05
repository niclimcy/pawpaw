//
//  ProfileEditorView+Layout.swift
//  pawpaw
//

import UIKit

extension ProfileEditorView {
    func build() {
        backgroundColor = UIColor.black.withAlphaComponent(0.55)
        isHidden = true
        accessibilityViewIsModal = true

        let card = UIView()
        Theme.styleCard(card)

        titleLabel.font = Theme.roundedFont(size: Theme.scaled(30))
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Theme.text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits = .header

        let saveButton = makeSaveButton()
        let cancelButton = makeCancelButton()
        let stack = UIStackView(arrangedSubviews: [
            titleLabel, makeNameField(), facePicker, makeCritterPicker(),
            saveButton, cancelButton, makeDeleteButton(),
        ])
        // Required, so fitting the card shrinks the face picker rather than squashing text.
        for view in [titleLabel, saveButton, cancelButton, deleteButton] {
            view.setContentCompressionResistancePriority(.required, for: .vertical)
        }
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 16
        stack.setCustomSpacing(8, after: saveButton)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
        ])
        centerInScroll(card, maxWidth: Theme.scaled(380))
    }

    private static let cardMargin: CGFloat = 24

    // When the card is taller than the screen, the face picker (just below `.defaultHigh`) shrinks
    // to fit; past that the card scrolls. The width wins over fitting, since narrowing the card
    // would only shrink the critters instead.
    private static let fillWidthPriority = UILayoutPriority.defaultHigh + 1
    private static let fitPriority = UILayoutPriority.defaultHigh

    /// Like `embedCentered`, but pinned above the keyboard.
    private func centerInScroll(_ card: UIView, maxWidth: CGFloat) {
        let margin = Self.cardMargin
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.keyboardDismissMode = .interactive
        scroll.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(container)
        card.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(card)

        // Lower priority so `maxWidth` wins.
        let fillWidth = card.widthAnchor.constraint(
            equalTo: container.widthAnchor, constant: -margin * 2)
        fillWidth.priority = Self.fillWidthPriority
        // Against the safe area rather than the scroll view, so the keyboard scrolls the card
        // instead of shrinking the faces.
        let fit = card.heightAnchor.constraint(
            lessThanOrEqualTo: safeAreaLayoutGuide.heightAnchor, constant: -margin * 2)
        fit.priority = Self.fitPriority
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),

            container.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            container.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            container.heightAnchor.constraint(
                greaterThanOrEqualTo: scroll.frameLayoutGuide.heightAnchor),

            card.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            card.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: margin),
            card.bottomAnchor.constraint(
                lessThanOrEqualTo: container.bottomAnchor, constant: -margin),
            // Required, so nothing inside can push the card past the screen margins.
            card.leadingAnchor.constraint(
                greaterThanOrEqualTo: container.leadingAnchor, constant: margin),
            card.trailingAnchor.constraint(
                lessThanOrEqualTo: container.trailingAnchor, constant: -margin),
            card.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth),
            fillWidth,
            fit,
        ])
    }
}
