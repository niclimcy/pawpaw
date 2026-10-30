//
//  StatsViewController.swift
//  pawpaw
//

import UIKit

final class StatsViewController: UIViewController, StatsViewProtocol {
    var presenter: StatsPresenterProtocol?
    var theme: PlayfieldTheme = .wood

    private let titleLabel = StatsViewController.makeLabel(size: Theme.scaled(34))
    private let summaryRow = StatsViewController.makeRow(spacing: 10, alignment: .fill)
    private let crittersStack = StatsViewController.makeCrittersStack()
    private let daysStack = StatsViewController.makeRow(spacing: 4)
    private let bestScoresRow = StatsViewController.makeRow(spacing: 10, alignment: .fill)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.baseColor
        installBackground(theme: theme)
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

        let dividers = (0..<3).map { _ in Self.makeDivider() }
        let content = UIStackView(arrangedSubviews: [
            summaryRow,
            dividers[0],
            Self.makeSectionHeader("Catches by critter"), crittersStack,
            dividers[1],
            Self.makeSectionHeader("Rounds in the last 7 days"), daysStack,
            dividers[2],
            Self.makeSectionHeader("Best scores"), bestScoresRow
        ])
        let sectionGap = Self.spacing(phone: 14, pad: 20)
        content.axis = .vertical
        content.alignment = .fill
        content.spacing = Self.spacing(phone: 10, pad: 14)
        // Room around the dividers so each section reads as its own block.
        for section in [summaryRow, crittersStack, daysStack] {
            content.setCustomSpacing(sectionGap, after: section)
        }
        for divider in dividers {
            content.setCustomSpacing(sectionGap, after: divider)
        }
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)

        let page = UIStackView(arrangedSubviews: [title, card, makeBackButton(), makeResetButton()])
        page.axis = .vertical
        page.alignment = .center
        page.spacing = Self.spacing(phone: 16, pad: 24)
        page.setCustomSpacing(8, after: page.arrangedSubviews[2])
        embedCentered(page, maxWidth: 560)

        let inset = Self.spacing(phone: 16, pad: 20)
        NSLayoutConstraint.activate([
            card.widthAnchor.constraint(equalTo: page.widthAnchor),

            content.topAnchor.constraint(equalTo: card.topAnchor, constant: inset),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -inset),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: inset),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -inset)
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
        button.addHoldToConfirm(self, action: #selector(resetHeld(_:)))
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

        summaryRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for metric in [viewModel.rounds, viewModel.catches] {
            summaryRow.addArrangedSubview(Self.makeMetricTile(metric))
        }
        let favorite = Self.makeTile(value: Self.makeFavoriteValue(imageName: viewModel.favoriteImageName), caption: "Favorite")
        favorite.accessibilityLabel = viewModel.favoriteAccessibilityLabel
        summaryRow.addArrangedSubview(favorite)

        bestScoresRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for metric in viewModel.bestScores {
            bestScoresRow.addArrangedSubview(Self.makeMetricTile(metric))
        }

        crittersStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let rows = stride(from: 0, to: viewModel.critters.count, by: Self.crittersPerRow).map {
            Array(viewModel.critters[$0..<min($0 + Self.crittersPerRow, viewModel.critters.count)])
        }
        for rowCritters in rows {
            let row = Self.makeRow(spacing: Self.isPad ? 8 : 4, alignment: .fill, distribution: Self.isPad ? .fill : .fillEqually)
            for critter in rowCritters {
                let tile = Self.makeCritterTile(imageName: critter.imageName, catches: critter.catches, isEmpty: critter.isEmpty)
                tile.accessibilityLabel = critter.accessibilityLabel
                row.addArrangedSubview(tile)
            }
            crittersStack.addArrangedSubview(row)
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

