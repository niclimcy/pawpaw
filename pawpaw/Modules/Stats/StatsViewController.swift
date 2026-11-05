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

    // Tightened when the regular layout doesn't fit, e.g. on an iPhone SE; see `applyMetrics()`.
    private var fit = CompactLayoutFit()
    private weak var layoutScroll: UIScrollView?
    private let page = UIStackView()
    private let footer = UIStackView()
    private let content = UIStackView()
    private var sectionBreaks: [UIView] = []
    private var cardInsets: [NSLayoutConstraint] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.baseColor
        installBackground(theme: theme)
        setupLayout()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentSizeChanged),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.viewWillAppear()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let scroll = layoutScroll else { return }
        let overflow =
            scroll.contentLayoutGuide.layoutFrame.height
            - scroll.frameLayoutGuide.layoutFrame.height
        let room = view.safeAreaLayoutGuide.layoutFrame.height
        if fit.update(needed: room + overflow, room: room) {
            applyMetrics()
        }
    }

    /// The text size changes what fits, so start from the regular layout and measure again.
    @objc private func contentSizeChanged() {
        fit.reset()
        applyMetrics()
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
        for subview in [
            summaryRow,
            dividers[0],
            Self.makeSectionHeader("Catches by critter"), crittersStack,
            dividers[1],
            Self.makeSectionHeader("Rounds in the last 7 days"), daysStack,
            dividers[2],
            Self.makeSectionHeader("Best scores"), bestScoresRow,
        ] {
            content.addArrangedSubview(subview)
        }
        content.axis = .vertical
        content.alignment = .fill
        // Room around the dividers so each section reads as its own block.
        sectionBreaks = [summaryRow, crittersStack, daysStack] + dividers
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)

        for subview in [title, card] {
            page.addArrangedSubview(subview)
        }
        page.axis = .vertical
        page.alignment = .center
        page.isLayoutMarginsRelativeArrangement = true

        // Back stays on screen; on short screens only the stats above it scroll.
        for subview in [makeBackButton(), makeResetButton()] {
            footer.addArrangedSubview(subview)
        }
        footer.axis = .vertical
        footer.alignment = .center
        footer.isLayoutMarginsRelativeArrangement = true

        // Margins live in the stacks so `applyMetrics()` can tighten them.
        layoutScroll = embedCentered(
            page, footer: footer, maxWidth: 560, verticalMargin: 0, footerSpacing: 0)

        // Constants are set in `applyMetrics()`; each is card edge to content edge, inward.
        cardInsets = [
            content.topAnchor.constraint(equalTo: card.topAnchor),
            card.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: content.trailingAnchor),
        ]
        NSLayoutConstraint.activate(
            cardInsets + [card.widthAnchor.constraint(equalTo: page.widthAnchor)])
        applyMetrics()
    }

    /// Regular sizes, or tighter ones when they don't fit. iPad always has room for the regular ones.
    private func applyMetrics() {
        let compact = fit.isCompact
        titleLabel.font = Theme.roundedFont(size: Theme.scaled(compact ? 28 : 34), weight: .heavy)

        page.spacing = Self.spacing(phone: compact ? 10 : 16, pad: 24)
        page.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: compact ? 12 : 24, leading: 0, bottom: 0, trailing: 0)

        content.spacing = Self.spacing(phone: compact ? 8 : 10, pad: 14)
        for section in sectionBreaks {
            content.setCustomSpacing(
                Self.spacing(phone: compact ? 10 : 14, pad: 20), after: section)
        }
        for inset in cardInsets {
            inset.constant = Self.spacing(phone: compact ? 12 : 16, pad: 20)
        }

        footer.spacing = compact ? 0 : 8
        footer.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: Self.spacing(phone: compact ? 10 : 16, pad: 24),
            leading: 0,
            bottom: compact ? 4 : 16,
            trailing: 0
        )
        view.setNeedsLayout()
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
        let button = Theme.plainButton(
            title: "Hold to reset stats", foreground: Theme.text.withAlphaComponent(0.75))
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
        alert.addAction(
            UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
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
        let favorite = Self.makeTile(
            value: Self.makeFavoriteValue(imageName: viewModel.favoriteImageName),
            caption: "Favorite")
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
            let row = Self.makeRow(
                spacing: Self.isPad ? 8 : 4, alignment: .fill,
                distribution: Self.isPad ? .fill : .fillEqually)
            for critter in rowCritters {
                let tile = Self.makeCritterTile(
                    imageName: critter.imageName, catches: critter.catches, isEmpty: critter.isEmpty
                )
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
