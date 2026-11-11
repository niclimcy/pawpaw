//
//  ProfilesViewController.swift
//  pawpaw
//

import UIKit

final class ProfilesViewController: UIViewController, ProfilesViewProtocol {
    var presenter: ProfilesPresenterProtocol?

    private let listStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        return stack
    }()

    let editor = ProfileEditorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupEditor()
        presenter?.viewDidLoad()
    }

    private func setupEditor() {
        editor.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editor)
        NSLayoutConstraint.activate([
            editor.topAnchor.constraint(equalTo: view.topAnchor),
            editor.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            editor.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editor.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        editor.onSave = { [weak self] name, face in
            self?.presenter?.didTapSave(name: name, face: face)
        }
        editor.onCancel = { [weak self] in self?.presenter?.didTapCancel() }
        editor.onDelete = { [weak self] in self?.presenter?.didConfirmDelete() }
        editor.onToggleCritter = { [weak self] kind in self?.presenter?.didToggleCritter(kind) }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.viewWillAppear()
    }

    // MARK: Layout
    private func setupLayout() {
        let title = UILabel()
        title.text = "Your Cats"
        title.font = Theme.roundedFont(size: 34)
        title.adjustsFontForContentSizeCategory = true
        title.textColor = Theme.text
        title.textAlignment = .center
        title.numberOfLines = 0
        title.accessibilityTraits = .header

        let card = UIView()
        Theme.styleCard(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        listStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(listStack)

        let page = UIStackView(arrangedSubviews: [title, card, makeAddButton(), makeBackButton()])
        page.axis = .vertical
        page.alignment = .center
        page.spacing = 20
        embedCentered(page, maxWidth: 560)

        NSLayoutConstraint.activate([
            card.widthAnchor.constraint(equalTo: page.widthAnchor),
            listStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            listStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            listStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            listStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])
    }

    // MARK: ProfilesViewProtocol
    func showTheme(_ theme: PlayfieldTheme) {
        view.backgroundColor = theme.baseColor
        installBackground(theme: theme)
    }

    func showProfiles(_ rows: [ProfileRow]) {
        for subview in listStack.arrangedSubviews { subview.removeFromSuperview() }
        for row in rows { listStack.addArrangedSubview(makeRow(row)) }
    }

    func showEditor(_ content: ProfileEditorContent) {
        editor.present(content)
    }

    func hideEditor() {
        editor.dismiss()
    }

    func showCritters(disabledKinds: Set<TargetKind>) {
        editor.showCritters(disabledKinds: disabledKinds)
    }

    func showCritterRefused(_ kind: TargetKind, hint: String) {
        editor.showCritterRefused(kind, hint: hint)
    }

    func showNameRequired() {
        editor.showNameRequired()
    }
}

@available(iOS 17.0, *)
#Preview {
    ProfilesRouter.createModule()
}
