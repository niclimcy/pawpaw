//
//  HomeViewController.swift
//  pawpaw
//

import UIKit

final class HomeViewController: UIViewController, HomeViewProtocol {
    var presenter: HomePresenterProtocol?
    private var shownTheme: PlayfieldTheme = .wood

    // Tightened when the regular layout doesn't fit, e.g. on an iPhone SE; see `applyMetrics()`.
    private var fit = CompactLayoutFit()
    private weak var layoutScroll: UIScrollView?
    private let mainStack = UIStackView()
    private let brandStack = UIStackView()
    private var cardFillsWidth: NSLayoutConstraint?
    /// Side by side when wide, since stacked doesn't fit a landscape iPhone Duo or iPad.
    private var isWide = false
    private var laidOutFor: LayoutEnvironment?
    private let footer = UIStackView()
    private let setupStack = UIStackView()
    private var setupCardInsets: [NSLayoutConstraint] = []
    private lazy var contentWidthLimit = mainStack.widthAnchor.constraint(
        lessThanOrEqualToConstant: Self.maxContentWidth)

    private let logoView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "logo_paw"))
        view.contentMode = .scaleAspectFit
        let aspect = view.image.map { $0.size.width / $0.size.height } ?? 1
        view.widthAnchor.constraint(equalTo: view.heightAnchor, multiplier: aspect).isActive = true
        view.isAccessibilityElement = false
        return view
    }()
    private lazy var logoHeight = logoView.heightAnchor.constraint(equalToConstant: 80)

    private let titleLabel: UILabel = {
        let label = Theme.makeLabel(size: 48)
        label.text = "Paw Paw"
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.accessibilityTraits = .header
        return label
    }()

    private static let profileFaceSide: CGFloat = 34

    private let topBar = UIStackView()
    private var contentBelowTopBar: NSLayoutConstraint?
    private var contentAtSafeArea: NSLayoutConstraint?
    private var usesSystemBar = false

    private let profileButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = CatProfile.defaultName
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.titleAlignment = .leading
        config.baseBackgroundColor = Theme.text
        config.baseForegroundColor = Theme.text
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 8, leading: 12, bottom: 8, trailing: 16)
        config.titleTextAttributesTransformer = Theme.fontTransformer(size: 18, weight: .bold)
        config.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            var outgoing = $0
            outgoing.font = Theme.roundedFont(size: 13, weight: .semibold)
            outgoing.foregroundColor = Theme.detailText
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(
            greaterThanOrEqualToConstant: Theme.minimumTapSize
        ).isActive = true
        button.accessibilityIdentifier = "profileButton"
        button.accessibilityHint = "Opens the list of cats"
        return button
    }()

    private let statsButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.image = UIImage(systemName: "chart.bar.fill")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: 18, weight: .semibold)
        config.baseBackgroundColor = Theme.text
        config.baseForegroundColor = Theme.text
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        let side: CGFloat = 48
        button.widthAnchor.constraint(equalToConstant: side).isActive = true
        button.heightAnchor.constraint(equalToConstant: side).isActive = true
        button.accessibilityIdentifier = "statsButton"
        button.accessibilityLabel = "Play stats"
        button.accessibilityHint = "Opens play statistics"
        return button
    }()

    /// Image only: a vertical bar has no room for the name.
    private lazy var profileItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: nil,
            style: .plain,
            target: self,
            action: #selector(profileTapped)
        )
        item.tintColor = Theme.text
        item.accessibilityIdentifier = "profileButton"
        item.accessibilityHint = "Opens the list of cats"
        return item
    }()

    private lazy var statsItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: UIImage(systemName: "chart.bar.fill"),
            style: .plain,
            target: self,
            action: #selector(statsTapped)
        )
        item.title = "Play stats"
        item.tintColor = Theme.text
        item.accessibilityIdentifier = "statsButton"
        item.accessibilityLabel = "Play stats"
        item.accessibilityHint = "Opens play statistics"
        return item
    }()

    private let highScoreLabel: UILabel = {
        let label = Theme.makeLabel(size: 18, weight: .bold)
        label.textColor = Theme.bodyText
        label.isHidden = true
        return label
    }()

    private let playfieldNoteLabel: UILabel = {
        let label = Theme.makeLabel(size: 14, weight: .semibold)
        label.textColor = Theme.sectionText
        label.isHidden = true
        label.accessibilityIdentifier = "playfieldNoteLabel"
        return label
    }()

    private static let modeFontSize: CGFloat = 16
    private static let playFontSize: CGFloat = 34
    private static let widePlayFontSize: CGFloat = 28
    /// Not orange, so PLAY stands out.
    private static let selectedTint = Theme.text
    private static let selectedText = Theme.background

    private let modeControl: UISegmentedControl = {
        let control = UISegmentedControl(
            items: SessionMode.allCases.map(\.title)
        )
        Theme.styleSegmented(
            control,
            fontSize: HomeViewController.modeFontSize,
            selectedTint: HomeViewController.selectedTint,
            selectedText: HomeViewController.selectedText
        )
        control.backgroundColor = Theme.controlTrack
        control.accessibilityIdentifier = "modeControl"
        control.accessibilityLabel = "Round length"
        return control
    }()

    private let themePicker = ThemePickerView()

    private let roundLengthLabel = HomeViewController.makeSectionLabel("ROUND LENGTH")
    private let afterRoundLabel = HomeViewController.makeSectionLabel("AFTER A ROUND")
    private let playgroundLabel = HomeViewController.makeSectionLabel("PLAYGROUND")

    private let afterRoundControl: UISegmentedControl = {
        let control = UISegmentedControl(
            items: AfterRoundMode.allCases.map(\.title)
        )
        Theme.styleSegmented(
            control,
            fontSize: HomeViewController.modeFontSize,
            selectedTint: HomeViewController.selectedTint,
            selectedText: HomeViewController.selectedText
        )
        control.backgroundColor = Theme.controlTrack
        control.accessibilityIdentifier = "afterRoundControl"
        control.accessibilityLabel = "After a round"
        control.accessibilityHint =
            "Whether catching the critter on the results starts another round"
        return control
    }()

    private let playButton: UIButton = {
        let button = Theme.filledButton(
            title: "PLAY",
            fontSize: HomeViewController.playFontSize,
            weight: .heavy,
            insets: NSDirectionalEdgeInsets(top: 20, leading: 56, bottom: 20, trailing: 56)
        )
        button.accessibilityIdentifier = "playButton"
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        installBackground(theme: .wood)
        setupNavigationItem()
        setupLayout()
        playButton.addTarget(
            self,
            action: #selector(playTapped),
            for: .touchUpInside
        )
        profileButton.addTarget(
            self,
            action: #selector(profileTapped),
            for: .touchUpInside
        )
        statsButton.addTarget(
            self,
            action: #selector(statsTapped),
            for: .touchUpInside
        )
        modeControl.addTarget(
            self,
            action: #selector(modeChanged),
            for: .valueChanged
        )
        afterRoundControl.addTarget(
            self,
            action: #selector(afterRoundChanged),
            for: .valueChanged
        )
        themePicker.onSelect = { [weak self] theme in
            self?.presenter?.didSelectTheme(theme)
        }
        layOutAgainWhenSizeClassChanges()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentSizeChanged),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBarPlacement(animated: animated)
        presenter?.viewWillAppear()
    }

    /// Every other screen draws its own controls, so the bar is Home's alone.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    /// Only iPhone Duo places a vertical bar, where a custom top bar would collide with the status bar.
    static func usesSystemBar(for traits: UITraitCollection) -> Bool {
        if #available(iOS 27.1, *) {
            return traits.verticalBarEdge != .unspecified
        }
        return false
    }

    private func updateBarPlacement(animated: Bool = false) {
        let system = Self.usesSystemBar(for: traitCollection)
        if system != usesSystemBar {
            usesSystemBar = system
            topBar.isHidden = system
            contentBelowTopBar?.isActive = !system
            contentAtSafeArea?.isActive = system
            navigationItem.leftBarButtonItem = system ? profileItem : nil
            navigationItem.rightBarButtonItem = system ? statsItem : nil
        }
        // Only while Home is on top; other screens keep the bar hidden.
        guard navigationController?.topViewController === self else { return }
        navigationController?.setNavigationBarHidden(!system, animated: animated)
    }

    @objc private func contentSizeChanged() {
        for control in [modeControl, afterRoundControl] {
            Theme.applySegmentedFonts(
                to: control,
                fontSize: Self.modeFontSize,
                selectedText: Self.selectedText
            )
        }
        // The text size changes what fits, so start from the regular layout and measure again.
        fit.reset()
        applyMetrics()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let environment = LayoutEnvironment(self)
        guard environment != laidOutFor else { return }
        laidOutFor = environment
        if usesWideLayout != isWide {
            isWide = usesWideLayout
            arrangeMainStack()
        }
        // Measured in the final size, not whichever step of a fold or rotation was last.
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
        // Folding, rotating or Split View can move the vertical bar in or out.
        updateBarPlacement()
    }

    /// Wide puts PLAY under the title, so each column is a whole and PLAY isn't stranded between them.
    private func arrangeMainStack() {
        mainStack.axis = isWide ? .horizontal : .vertical
        cardFillsWidth?.isActive = !isWide
        let target = isWide ? brandStack : footer
        for subview in [playButton, playfieldNoteLabel, highScoreLabel]
        where subview.superview !== target {
            target.addArrangedSubview(subview)
        }
    }

    private func setupNavigationItem() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance
    }

    private func setupLayout() {
        setupTopBar()
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        contentBelowTopBar = content.topAnchor.constraint(equalTo: topBar.bottomAnchor)
        contentAtSafeArea = content.topAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.topAnchor)
        contentBelowTopBar?.isActive = true
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            topBar.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            topBar.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        for subview in [logoView, titleLabel] {
            brandStack.addArrangedSubview(subview)
        }
        brandStack.axis = .vertical
        brandStack.alignment = .center
        // The card takes the spare width when side by side, so the title isn't squeezed.
        brandStack.setContentHuggingPriority(.required, for: .horizontal)
        brandStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        let setupCard = makeSetupCard()
        for subview in [brandStack, setupCard] {
            mainStack.addArrangedSubview(subview)
        }
        mainStack.alignment = .center
        mainStack.isLayoutMarginsRelativeArrangement = true
        cardFillsWidth = setupCard.widthAnchor.constraint(equalTo: mainStack.widthAnchor)
        arrangeMainStack()
        logoHeight.isActive = true

        // PLAY stays on screen; on short screens only the settings above it scroll.
        for subview in [playButton, playfieldNoteLabel, highScoreLabel] {
            footer.addArrangedSubview(subview)
        }
        footer.axis = .vertical
        footer.alignment = .center
        footer.isLayoutMarginsRelativeArrangement = true

        // Margins live in the stacks so `applyMetrics()` can tighten them.
        layoutScroll = embedCentered(
            mainStack,
            footer: footer,
            maxWidth: Self.wideMaxContentWidth,
            verticalMargin: 0,
            footerSpacing: 0,
            in: content
        )
        // Required, so it narrows the content below `embedCentered`'s wide-layout width.
        contentWidthLimit.isActive = true
        applyMetrics()
        updateBarPlacement()
    }

    private func setupTopBar() {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        // A long name truncates before the stats button is squeezed.
        profileButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        statsButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        for subview in [profileButton, spacer, statsButton] {
            topBar.addArrangedSubview(subview)
        }
        topBar.axis = .horizontal
        topBar.alignment = .center
        topBar.spacing = 12
        topBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBar)
    }

    private func applyMetrics() {
        contentWidthLimit.constant = isWide ? Self.wideMaxContentWidth : Self.maxContentWidth
        let compact = fit.isCompact
        logoHeight.constant = compact ? 52 : 80
        titleLabel.font = Theme.roundedFont(size: compact ? 38 : 48, weight: .heavy)

        brandStack.spacing = compact ? 8 : 12
        mainStack.spacing = isWide ? (compact ? 24 : 40) : (compact ? 14 : 28)
        mainStack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: compact ? 12 : 24, leading: 0, bottom: 0, trailing: 0)

        let sectionGap: CGFloat = compact ? 12 : 20
        setupStack.setCustomSpacing(sectionGap, after: modeControl)
        setupStack.setCustomSpacing(sectionGap, after: afterRoundControl)
        for inset in setupCardInsets {
            inset.constant = compact ? 14 : 18
        }

        if isWide {
            brandStack.setCustomSpacing(compact ? 20 : 32, after: titleLabel)
            brandStack.setCustomSpacing(8, after: playButton)
        }
        footer.spacing = compact ? 6 : 12
        // Empty when wide, so no margins either or it leaves a gap at the bottom.
        footer.directionalLayoutMargins =
            isWide
            ? .zero
            : NSDirectionalEdgeInsets(
                top: compact ? 16 : 28,
                leading: 0,
                bottom: compact ? 12 : 24,
                trailing: 0
            )
        // Narrower and shorter beside the title, which it shouldn't outweigh.
        let playPadding: CGFloat = isWide ? 10 : compact ? 14 : 20
        let playSidePadding: CGFloat = isWide ? 40 : 56
        playButton.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: playPadding, leading: playSidePadding,
            bottom: playPadding, trailing: playSidePadding)
        playButton.configuration?.titleTextAttributesTransformer = Theme.fontTransformer(
            size: isWide ? Self.widePlayFontSize : Self.playFontSize, weight: .heavy)
        view.setNeedsLayout()
    }

    private static let maxContentWidth: CGFloat = 520
    private static let wideMaxContentWidth: CGFloat = 900

    private func makeSetupCard() -> UIView {
        let stack = setupStack
        for subview in [
            roundLengthLabel, modeControl,
            afterRoundLabel, afterRoundControl,
            playgroundLabel, themePicker,
        ] {
            stack.addArrangedSubview(subview)
        }
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        let card = UIView()
        Theme.styleCard(card)
        card.backgroundColor = Theme.translucentPanel
        card.layer.borderWidth = 2
        card.layer.borderColor = Theme.cardOutline.cgColor
        card.layer.cornerRadius = 24
        card.addSubview(stack)
        // Constants are set in `applyMetrics()`; each is card edge to stack edge, inward.
        setupCardInsets = [
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            card.bottomAnchor.constraint(equalTo: stack.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
        ]
        NSLayoutConstraint.activate(setupCardInsets)
        return card
    }

    private static func makeSectionLabel(_ text: String) -> UILabel {
        let label = Theme.makeLabel(size: 13, weight: .heavy)
        label.text = text
        label.textAlignment = .natural
        label.textColor = Theme.sectionText
        label.accessibilityTraits = .header
        return label
    }

    @objc private func playTapped() {
        presenter?.didTapPlay()
    }

    @objc private func profileTapped() {
        presenter?.didTapProfile()
    }

    @objc private func modeChanged() {
        presenter?.didSelectMode(
            SessionMode.allCases[modeControl.selectedSegmentIndex]
        )
    }

    @objc private func afterRoundChanged() {
        presenter?.didSelectAfterRound(
            AfterRoundMode.allCases[afterRoundControl.selectedSegmentIndex]
        )
    }

    @objc private func statsTapped() {
        presenter?.didRequestStats()
    }

    // MARK: HomeViewProtocol
    func showMode(_ mode: SessionMode) {
        modeControl.selectedSegmentIndex =
            SessionMode.allCases.firstIndex(of: mode) ?? 0
    }

    func showAfterRound(_ afterRound: AfterRoundMode, isAvailable: Bool) {
        afterRoundControl.selectedSegmentIndex =
            AfterRoundMode.allCases.firstIndex(of: afterRound) ?? 0
        afterRoundLabel.isHidden = !isAvailable
        afterRoundControl.isHidden = !isAvailable
    }

    func showTheme(_ theme: PlayfieldTheme) {
        themePicker.select(theme)
        guard theme != shownTheme else { return }
        shownTheme = theme
        installBackground(theme: theme)
    }

    func showHighScore(_ score: Int?) {
        let best = score ?? 0
        highScoreLabel.isHidden = best <= 0
        highScoreLabel.attributedText = Theme.symbolText(
            "trophy.fill", "Best: \(best)", font: highScoreLabel.font,
            color: highScoreLabel.textColor
        )
        highScoreLabel.accessibilityLabel = "Best: \(best)"
    }

    func showPlayfieldNote(_ text: String?) {
        playfieldNoteLabel.isHidden = text == nil
        playfieldNoteLabel.accessibilityLabel = text
        guard let text else {
            playfieldNoteLabel.attributedText = nil
            return
        }
        playfieldNoteLabel.attributedText = Theme.symbolText(
            "iphone",
            text,
            font: playfieldNoteLabel.font,
            color: playfieldNoteLabel.textColor
        )
    }

    func showProfile(name: String, face: CatFace, favorite: String?) {
        let image = face.image(side: Self.profileFaceSide)
        profileButton.configuration?.title = name
        profileButton.configuration?.subtitle = favorite
        profileButton.configuration?.image = image
        profileItem.image = image
        let label = [name, face.title, favorite]
            .compactMap { $0 }
            .joined(separator: ", ")
        profileButton.accessibilityLabel = label
        profileItem.accessibilityLabel = label
    }
}

@available(iOS 17.0, *)
#Preview {
    HomeRouter.createModule()
}
