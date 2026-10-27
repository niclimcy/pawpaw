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

    /// False when only one cat is left, since the last cat can't be deleted.
    var canDelete = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        installBackground(theme: .wood)
        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.viewWillAppear()
    }

    // MARK: Layout
    private func setupLayout() {
        let title = UILabel()
        title.text = "Your Cats"
        title.font = Theme.roundedFont(size: Theme.scaled(34))
        title.textColor = Theme.text
        title.textAlignment = .center

        let card = UIView()
        card.backgroundColor = Theme.panel
        card.layer.borderWidth = 3
        card.layer.borderColor = Theme.gold.withAlphaComponent(0.6).cgColor
        card.layer.cornerRadius = 28
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
            listStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])
    }

    // MARK: ProfilesViewProtocol
    func showProfiles(_ rows: [ProfileRow], canDelete: Bool) {
        self.canDelete = canDelete
        listStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        rows.forEach { listStack.addArrangedSubview(makeRow($0)) }
    }
}

@available(iOS 17.0, *)
#Preview {
    ProfilesRouter.createModule()
}
