//
//  StatsViewController.swift
//  pawpaw
//

import UIKit

final class StatsViewController: UIViewController, StatsViewProtocol {
    var presenter: StatsPresenterProtocol?

    private let titleLabel = StatsViewController.makeLabel(size: Theme.scaled(34))
    private let summaryLabel = StatsViewController.makeLabel(size: 26)
    private let favoriteLabel = StatsViewController.makeLabel(size: 20, weight: .semibold)
    private let crittersStack = StatsViewController.makeRow()
    private let daysStack = StatsViewController.makeRow()
    private let bestScoresLabel = StatsViewController.makeLabel(size: 18, weight: .semibold)

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
        let title = titleLabel
        title.text = "Play Stats"
        title.accessibilityTraits = .header

        let card = UIView()
        Theme.styleCard(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        let crittersTitle = Self.makeLabel(size: 16, weight: .bold)
        crittersTitle.text = "Catches by critter"
        let daysTitle = Self.makeLabel(size: 16, weight: .bold)
        daysTitle.text = "Rounds in the last 7 days"
        let bestTitle = Self.makeLabel(size: 16, weight: .bold)
        bestTitle.text = "Best scores"
        [crittersTitle, daysTitle, bestTitle].forEach { $0.accessibilityTraits = .header }

        let content = UIStackView(arrangedSubviews: [
            summaryLabel, favoriteLabel,
            crittersTitle, crittersStack,
            daysTitle, daysStack,
            bestTitle, bestScoresLabel
        ])
        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 12
        content.setCustomSpacing(24, after: favoriteLabel)
        content.setCustomSpacing(24, after: crittersStack)
        content.setCustomSpacing(24, after: daysStack)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)

        let page = UIStackView(arrangedSubviews: [title, card, makeBackButton(), makeResetButton()])
        page.axis = .vertical
        page.alignment = .center
        page.spacing = 20
        embedCentered(page, maxWidth: 560)

        NSLayoutConstraint.activate([
            card.widthAnchor.constraint(equalTo: page.widthAnchor),

            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24)
        ])
    }
}

// MARK: - Buttons and actions
extension StatsViewController {
    fileprivate func makeBackButton() -> UIButton {
        let button = Theme.filledButton(title: "Back")
        button.accessibilityIdentifier = "statsBackButton"
        button.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return button
    }

    fileprivate func makeResetButton() -> UIButton {
        let button = Theme.plainButton(title: "Hold to reset stats", foreground: Theme.text.withAlphaComponent(0.75))
        button.accessibilityIdentifier = "statsResetButton"
        button.accessibilityHint = "Press and hold to erase all play statistics"
        button.addGestureRecognizer(UILongPressGestureRecognizer.holdToConfirm(self, #selector(resetHeld(_:))))
        return button
    }

    @objc private func backTapped() {
        presenter?.didTapBack()
    }

    @objc private func resetHeld(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let alert = UIAlertController(
            title: "Reset stats?",
            message: "This erases all rounds, catches and play history. Best scores are kept.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            self?.presenter?.didConfirmReset()
        })
        present(alert, animated: true)
    }
}

// MARK: - StatsViewProtocol
extension StatsViewController {
    func showStats(_ viewModel: StatsViewModel) {
        titleLabel.text = viewModel.title
        summaryLabel.text = viewModel.summary
        favoriteLabel.attributedText = Self.favoriteText(viewModel.favorite, imageName: viewModel.favoriteImageName, font: favoriteLabel.font)
        bestScoresLabel.text = viewModel.bestScores.joined(separator: "   ")

        favoriteLabel.accessibilityLabel = viewModel.favoriteAccessibilityLabel

        crittersStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for row in viewModel.critters {
            let column = Self.makeColumn(imageName: row.imageName, size: Theme.scaled(44), bottom: row.catches)
            column.accessibilityLabel = row.accessibilityLabel
            crittersStack.addArrangedSubview(column)
        }

        daysStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let maxRounds = max(viewModel.days.map(\.rounds).max() ?? 0, 1)
        for day in viewModel.days {
            let bar = Self.makeBar(label: day.label, rounds: day.rounds, maxRounds: maxRounds)
            bar.accessibilityLabel = day.accessibilityLabel
            daysStack.addArrangedSubview(bar)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    StatsRouter.createModule()
}

