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
        let stack = UIStackView(arrangedSubviews: [
            titleLabel, makeNameField(), facePicker, makeCritterPicker(),
            saveButton, makeCancelButton(), makeDeleteButton()
        ])
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
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24)
        ])
        centerInScroll(card, maxWidth: Theme.scaled(380))
    }

    /// Like `embedCentered`, but pinned above the keyboard.
    private func centerInScroll(_ card: UIView, maxWidth: CGFloat) {
        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        scroll.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(container)
        card.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(card)

        let fillWidth = card.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -48)
        fillWidth.priority = .defaultHigh
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
            container.heightAnchor.constraint(greaterThanOrEqualTo: scroll.frameLayoutGuide.heightAnchor),

            card.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            card.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: 24),
            card.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -24),
            card.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth),
            fillWidth
        ])
    }
}
