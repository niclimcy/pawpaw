//
//  StatsViewController.swift
//  pawpaw
//

import UIKit

final class StatsViewController: UIViewController, StatsViewProtocol {
    var presenter: StatsPresenterProtocol?

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
        let title = Self.makeLabel(size: Theme.scaled(34))
        title.text = "Play Stats"

        let card = UIView()
        card.backgroundColor = Theme.panel
        card.layer.borderWidth = 3
        card.layer.borderColor = Theme.gold.withAlphaComponent(0.6).cgColor
        card.layer.cornerRadius = 28
        card.translatesAutoresizingMaskIntoConstraints = false

        let crittersTitle = Self.makeLabel(size: 16, weight: .bold)
        crittersTitle.text = "Catches by critter"
        let daysTitle = Self.makeLabel(size: 16, weight: .bold)
        daysTitle.text = "Rounds in the last 7 days"
        let bestTitle = Self.makeLabel(size: 16, weight: .bold)
        bestTitle.text = "Best scores"

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

        // One centered column: scrolls on small phones and in landscape, capped in width on iPad.
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
        var config = UIButton.Configuration.filled()
        config.title = "Back"
        config.baseBackgroundColor = Theme.accent
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 36, bottom: 14, trailing: 36)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.roundedFont(size: Theme.scaled(20), weight: .bold)
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.minimumTapSize).isActive = true
        button.accessibilityIdentifier = "statsBackButton"
        button.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return button
    }

    /// Erasing history is deliberate, so the button needs a hold before it asks for confirmation.
    fileprivate func makeResetButton() -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = "Hold to reset stats"
        config.baseForegroundColor = Theme.text.withAlphaComponent(0.75)
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.roundedFont(size: Theme.scaled(16), weight: .bold)
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.minimumTapSize).isActive = true
        button.accessibilityIdentifier = "statsResetButton"
        button.accessibilityHint = "Press and hold to erase all play statistics"
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(resetHeld(_:)))
        hold.minimumPressDuration = 1.5
        button.addGestureRecognizer(hold)
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
        summaryLabel.text = viewModel.summary
        favoriteLabel.text = viewModel.favorite
        bestScoresLabel.text = viewModel.bestScores.joined(separator: "   ")

        crittersStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for row in viewModel.critters {
            crittersStack.addArrangedSubview(Self.makeColumn(top: row.emoji, topSize: 30, bottom: row.catches))
        }

        daysStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let maxRounds = max(viewModel.days.map(\.rounds).max() ?? 0, 1)
        for day in viewModel.days {
            daysStack.addArrangedSubview(Self.makeBar(label: day.label, rounds: day.rounds, maxRounds: maxRounds))
        }
    }
}

#Preview {
    StatsRouter.createModule()
}

