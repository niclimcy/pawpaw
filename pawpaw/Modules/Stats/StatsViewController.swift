//
//  StatsViewController.swift
//  pawpaw
//

import UIKit

final class StatsViewController: UIViewController, StatsViewProtocol {
    // TODO: To remove after swift bug is resolved.
    nonisolated deinit {}

    var presenter: StatsPresenterProtocol?

    private let titleLabel = Theme.makeLabel(size: 34)
    private let daysHeader = StatsViewController.makeSectionHeader("")
    private let summaryRow = StatsViewController.makeRow(spacing: 10, alignment: .fill)
    private let crittersStack = StatsViewController.makeCrittersStack()
    private let daysStack = StatsViewController.makeRow(spacing: 4)
    private let bestScoresRow = StatsViewController.makeRow(spacing: 10, alignment: .fill)

    // Tightened when the regular layout doesn't fit, e.g. on an iPhone SE; see `applyMetrics()`.
    private var fit = CompactLayoutFit()
    private weak var layoutScroll: UIScrollView?
    private let page = UIStackView()
    private let footer = UIStackView()
    /// Side by side in the compact layout, to free a row for the stats.
    private let footerButtons = UIStackView()
    private let content = UIStackView()
    private let columnDivider = UIView()
    private var stackedDivider: NSLayoutConstraint?
    private var sideBySideDivider: [NSLayoutConstraint] = []
    private var pageMaxWidth: NSLayoutConstraint?
    private var isWide = false
    private var laidOutFor: LayoutEnvironment?
    private var sectionBreaks: [UIView] = []
    private var cardInsets: [NSLayoutConstraint] = []
    private let topRoom = UIView()
    /// Below the scroll view's fit, so the room shrinks to nothing before the page would scroll.
    private lazy var topRoomHeight: NSLayoutConstraint = {
        let height = topRoom.heightAnchor.constraint(equalToConstant: 0)
        height.priority = UILayoutPriority(700)
        return height
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        layOutAgainWhenSizeClassChanges()
        presenter?.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(measureFitOnNextLayout),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.viewWillAppear()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        let insets = view.safeAreaInsets
        let balance = Self.bottomInsetBalance(
            top: insets.top, bottom: insets.bottom - additionalSafeAreaInsets.bottom)
        guard additionalSafeAreaInsets.bottom != balance else { return }
        additionalSafeAreaInsets.bottom = balance
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let environment = LayoutEnvironment(self)
        guard environment != laidOutFor else { return }
        laidOutFor = environment
        isWide = usesWideLayout
        // Measured again from the regular layout, so a tighter one chosen partway through a fold
        // doesn't stick once the screen has room.
        fit.reset()
        applyMetrics()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let scroll = layoutScroll, fit.update(scroll: scroll) {
            applyMetrics()
            // A layout request made during this pass waits for the next one, such as a tap.
            view.layoutIfNeeded()
        }
    }

    @objc private func measureFitOnNextLayout() {
        laidOutFor = nil
        view.setNeedsLayout()
    }

    // MARK: Layout
    private func setupLayout() {
        let title = titleLabel
        title.text = "Play Stats"
        title.accessibilityTraits = .header

        let card = UIView()
        Theme.styleCard(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        let dividers = (0..<2).map { _ in Self.makeDivider() }
        let leftColumn = UIStackView(arrangedSubviews: [
            summaryRow,
            dividers[0],
            Self.makeSectionHeader("Catches by critter"), crittersStack,
        ])
        let rightColumn = UIStackView(arrangedSubviews: [
            daysHeader, daysStack,
            dividers[1],
            Self.makeSectionHeader("Best scores"), bestScoresRow,
        ])
        columnDivider.backgroundColor = Theme.divider
        for subview in [leftColumn, columnDivider, rightColumn] {
            content.addArrangedSubview(subview)
        }
        for column in [leftColumn, rightColumn] {
            column.axis = .vertical
            column.alignment = .fill
        }
        stackedDivider = columnDivider.heightAnchor.constraint(equalToConstant: 1)
        sideBySideDivider = [
            columnDivider.widthAnchor.constraint(equalToConstant: 1),
            columnDivider.heightAnchor.constraint(equalTo: content.heightAnchor),
        ]
        leftColumn.widthAnchor.constraint(equalTo: rightColumn.widthAnchor).isActive = true
        // Room around the dividers so each section reads as its own block.
        sectionBreaks = [summaryRow, daysStack, leftColumn, columnDivider] + dividers
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        // Critter counts and day bars stay small by design, so a long press shows them enlarged.
        for stack in [crittersStack, daysStack] {
            stack.addInteraction(UILargeContentViewerInteraction())
        }

        topRoom.isAccessibilityElement = false
        topRoomHeight.isActive = true
        for subview in [topRoom, title, card] {
            page.addArrangedSubview(subview)
        }
        page.setCustomSpacing(0, after: topRoom)
        page.axis = .vertical
        page.alignment = .fill
        page.isLayoutMarginsRelativeArrangement = true

        // Back stays on screen; on short screens only the stats above it scroll.
        let backButton = makeBackButton()
        // Side by side on a narrow screen, the reset text wraps rather than squeezing Back.
        backButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        for subview in [backButton, makeResetButton()] {
            footerButtons.addArrangedSubview(subview)
        }
        footerButtons.alignment = .center
        footer.addArrangedSubview(footerButtons)
        footer.axis = .vertical
        footer.alignment = .center
        footer.isLayoutMarginsRelativeArrangement = true

        // Margins live in the stacks so `applyMetrics()` can tighten them.
        layoutScroll = embedCentered(
            page, footer: footer, maxWidth: 900, verticalMargin: 0, footerSpacing: 0)
        pageMaxWidth = page.widthAnchor.constraint(lessThanOrEqualToConstant: 560)

        // Constants are set in `applyMetrics()`; each is card edge to content edge, inward.
        cardInsets = [
            content.topAnchor.constraint(equalTo: card.topAnchor),
            card.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: content.trailingAnchor),
        ]
        NSLayoutConstraint.activate(cardInsets)
        applyMetrics()
    }

    private func applyMetrics() {
        let compact = fit.isCompact
        content.axis = isWide ? .horizontal : .vertical
        content.alignment = isWide ? .top : .fill
        stackedDivider?.isActive = !isWide
        for constraint in sideBySideDivider { constraint.isActive = isWide }
        pageMaxWidth?.isActive = !isWide
        // Three tiles abreast leave too little width for accessibility text sizes.
        let stacksTiles = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        for row in [summaryRow, bestScoresRow] {
            row.axis = stacksTiles ? .vertical : .horizontal
        }
        titleLabel.font = Theme.roundedFont(size: compact ? 28 : 34, weight: .heavy)

        page.spacing = compact ? 10 : 16
        page.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: compact ? 12 : 24, leading: 0, bottom: 0, trailing: 0)
        // Compact is only just too tall, so its spare space goes above the title, not below the footer.
        topRoomHeight.constant = compact ? 16 : 0

        let itemSpacing: CGFloat = compact ? 8 : 10
        for stack in [content] + content.arrangedSubviews.compactMap({ $0 as? UIStackView }) {
            stack.spacing = itemSpacing
        }
        for section in sectionBreaks {
            (section.superview as? UIStackView)?.setCustomSpacing(
                compact ? 8 : 14, after: section)
        }
        for inset in cardInsets {
            inset.constant = compact ? 12 : 16
        }

        footerButtons.axis = compact ? .horizontal : .vertical
        footerButtons.spacing = compact ? 16 : 8
        footer.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: compact ? 10 : 16,
            leading: 0,
            bottom: compact ? 4 : 16,
            trailing: 0
        )
        view.setNeedsLayout()
    }

    /// Folded iPhone Duo has a home indicator inset but no top inset, as its status bar runs down
    /// the side. Giving half the difference back keeps the page centered on screen.
    static func bottomInsetBalance(top: CGFloat, bottom: CGFloat) -> CGFloat {
        -max(bottom - top, 0) / 2
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
            title: "Hold to reset stats", foreground: Theme.detailText)
        button.accessibilityIdentifier = "statsResetButton"
        button.accessibilityHint = "Press and hold to erase all play statistics"
        button.addHoldToConfirm(self, action: #selector(resetHeld(_:)))
        button.setHoldAccessibilityAction("Reset stats") { [weak self] in
            self?.confirmReset()
        }
        return button
    }

    @objc private func backTapped() {
        presenter?.didTapBack()
    }

    @objc private func resetHeld(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        confirmReset()
    }

    private func confirmReset() {
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
    func showTheme(_ theme: PlayfieldTheme) {
        view.backgroundColor = theme.baseColor
        installBackground(theme: theme)
    }

    func showStats(_ viewModel: StatsViewModel) {
        titleLabel.text = viewModel.title
        daysHeader.text = viewModel.daysHeading

        for subview in summaryRow.arrangedSubviews { subview.removeFromSuperview() }
        for metric in [viewModel.rounds, viewModel.catches] {
            summaryRow.addArrangedSubview(Self.makeMetricTile(metric))
        }
        let favorite = Self.makeTile(
            value: Self.makeFavoriteValue(imageName: viewModel.favoriteImageName),
            caption: "Favorite")
        favorite.accessibilityLabel = viewModel.favoriteAccessibilityLabel
        summaryRow.addArrangedSubview(favorite)

        for subview in bestScoresRow.arrangedSubviews { subview.removeFromSuperview() }
        for metric in viewModel.bestScores {
            bestScoresRow.addArrangedSubview(Self.makeMetricTile(metric))
        }

        for subview in crittersStack.arrangedSubviews { subview.removeFromSuperview() }
        let rows = stride(from: 0, to: viewModel.critters.count, by: Self.crittersPerRow).map {
            Array(viewModel.critters[$0..<min($0 + Self.crittersPerRow, viewModel.critters.count)])
        }
        for rowCritters in rows {
            let row = Self.makeRow(spacing: 4, alignment: .fill)
            for critter in rowCritters {
                let tile = Self.makeCritterTile(
                    imageName: critter.imageName, catches: critter.catches, isEmpty: critter.isEmpty
                )
                tile.accessibilityLabel = critter.accessibilityLabel
                tile.largeContentTitle = critter.accessibilityLabel
                row.addArrangedSubview(tile)
            }
            crittersStack.addArrangedSubview(row)
        }

        for subview in daysStack.arrangedSubviews { subview.removeFromSuperview() }
        let maxRounds = max(viewModel.days.map(\.rounds).max() ?? 0, 1)
        for day in viewModel.days {
            let bar = Self.makeBar(label: day.label, rounds: day.rounds, maxRounds: maxRounds)
            bar.accessibilityLabel = day.accessibilityLabel
            bar.largeContentTitle = day.accessibilityLabel
            daysStack.addArrangedSubview(bar)
        }
        measureFitOnNextLayout()
    }
}

@available(iOS 17.0, *)
#Preview {
    StatsRouter.createModule()
}
