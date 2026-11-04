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
    private let footer = UIStackView()
    private let setupStack = UIStackView()
    private var setupCardInsets: [NSLayoutConstraint] = []

    private let logoView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "logo_paw"))
        view.contentMode = .scaleAspectFit
        let aspect = view.image.map { $0.size.width / $0.size.height } ?? 1
        view.widthAnchor.constraint(equalTo: view.heightAnchor, multiplier: aspect).isActive = true
        view.isAccessibilityElement = false
        return view
    }()
    private lazy var logoHeight = logoView.heightAnchor.constraint(equalToConstant: Theme.scaled(80))

    private let titleLabel: UILabel = {
        let label = HomeViewController.makeLabel(size: 48)
        label.text = "Paw Paw"
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.accessibilityTraits = .header
        return label
    }()

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
            top: 8,
            leading: 12,
            bottom: 8,
            trailing: 16
        )
        config.titleTextAttributesTransformer = Theme.fontTransformer(
            size: 18,
            weight: .bold
        )
        config.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.roundedFont(size: Theme.scaled(13), weight: .semibold)
            outgoing.foregroundColor = Theme.text.withAlphaComponent(0.75)
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
            pointSize: Theme.scaled(18),
            weight: .semibold
        )
        config.baseBackgroundColor = Theme.text
        config.baseForegroundColor = Theme.text
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        let side = max(Theme.minimumTapSize, Theme.scaled(48))
        button.widthAnchor.constraint(equalToConstant: side).isActive = true
        button.heightAnchor.constraint(equalToConstant: side).isActive = true
        button.accessibilityIdentifier = "statsButton"
        button.accessibilityLabel = "Play stats"
        button.accessibilityHint = "Opens play statistics"
        return button
    }()

    private let highScoreLabel: UILabel = {
        let label = HomeViewController.makeLabel(size: 18, weight: .bold)
        label.textColor = Theme.text.withAlphaComponent(0.85)
        label.isHidden = true
        return label
    }()

    private let playfieldNoteLabel: UILabel = {
        let label = HomeViewController.makeLabel(size: 14, weight: .semibold)
        label.textColor = Theme.text.withAlphaComponent(0.65)
        label.isHidden = true
        label.accessibilityIdentifier = "playfieldNoteLabel"
        return label
    }()

    private static let modeFontSize: CGFloat = 16
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
        control.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        control.accessibilityIdentifier = "modeControl"
        control.accessibilityLabel = "Round length"
        return control
    }()

    private let themePicker = ThemePickerView()

    private let afterRoundLabel = HomeViewController.makeSectionLabel("AFTER A ROUND")

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
        control.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        control.accessibilityIdentifier = "afterRoundControl"
        control.accessibilityLabel = "After a round"
        control.accessibilityHint = "Whether catching the critter on the results starts another round"
        return control
    }()

    private let playButton: UIButton = {
        let button = Theme.filledButton(
            title: "PLAY",
            fontSize: 34,
            weight: .heavy,
            insets: NSDirectionalEdgeInsets(
                top: Theme.scaled(20),
                leading: Theme.scaled(56),
                bottom: Theme.scaled(20),
                trailing: Theme.scaled(56)
            )
        )
        button.accessibilityIdentifier = "playButton"
        return button
    }()

    private static func makeLabel(size: CGFloat, weight: UIFont.Weight = .heavy)
        -> UILabel
    {
        let label = UILabel()
        label.font = Theme.roundedFont(size: Theme.scaled(size), weight: weight)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Theme.text
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        installBackground(theme: .wood)
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let scroll = layoutScroll, let host = scroll.superview else { return }
        let overflow = scroll.contentLayoutGuide.layoutFrame.height - scroll.frameLayoutGuide.layoutFrame.height
        let room = host.safeAreaLayoutGuide.layoutFrame.height
        if fit.update(needed: room + overflow, room: room) {
            applyMetrics()
        }
    }

    private func setupLayout() {
        let topBar = makeTopBar()
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        let margin = Theme.scaled(16)
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            topBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: margin),
            topBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -margin),

            content.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            content.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let setupCard = makeSetupCard()
        for subview in [logoView, titleLabel, setupCard] {
            mainStack.addArrangedSubview(subview)
        }
        mainStack.axis = .vertical
        mainStack.alignment = .center
        mainStack.isLayoutMarginsRelativeArrangement = true
        setupCard.widthAnchor.constraint(equalTo: mainStack.widthAnchor).isActive = true
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
            maxWidth: Self.maxContentWidth,
            verticalMargin: 0,
            footerSpacing: 0,
            in: content
        )
        applyMetrics()
    }

    /// Regular sizes, or tighter ones when they don't fit. iPad always has room for the regular ones.
    private func applyMetrics() {
        let compact = fit.isCompact
        logoHeight.constant = Theme.scaled(compact ? 52 : 80)
        titleLabel.font = Theme.roundedFont(size: Theme.scaled(compact ? 38 : 48), weight: .heavy)

        mainStack.spacing = Theme.scaled(compact ? 8 : 12)
        mainStack.setCustomSpacing(Theme.scaled(compact ? 14 : 28), after: titleLabel)
        mainStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: compact ? 12 : 24, leading: 0, bottom: 0, trailing: 0)

        let sectionGap = Theme.scaled(compact ? 12 : 20)
        setupStack.setCustomSpacing(sectionGap, after: modeControl)
        setupStack.setCustomSpacing(sectionGap, after: afterRoundControl)
        for inset in setupCardInsets {
            inset.constant = Theme.scaled(compact ? 14 : 18)
        }

        footer.spacing = Theme.scaled(compact ? 6 : 12)
        footer.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: Theme.scaled(compact ? 16 : 28),
            leading: 0,
            bottom: compact ? 12 : 24,
            trailing: 0
        )
        let playPadding = Theme.scaled(compact ? 14 : 20)
        playButton.configuration?.contentInsets.top = playPadding
        playButton.configuration?.contentInsets.bottom = playPadding
        view.setNeedsLayout()
    }

    private static var maxContentWidth: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 660 : 520
    }

    private func makeTopBar() -> UIView {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        profileButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        statsButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        let bar = UIStackView(arrangedSubviews: [profileButton, spacer, statsButton])
        bar.axis = .horizontal
        bar.alignment = .center
        bar.spacing = 12
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)
        return bar
    }

    private func makeSetupCard() -> UIView {
        let stack = setupStack
        for subview in [
            Self.makeSectionLabel("ROUND LENGTH"), modeControl,
            afterRoundLabel, afterRoundControl,
            Self.makeSectionLabel("PLAYGROUND"), themePicker,
        ] {
            stack.addArrangedSubview(subview)
        }
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        let card = UIView()
        Theme.styleCard(card)
        card.backgroundColor = Theme.panel.withAlphaComponent(0.85)
        card.layer.borderWidth = 2
        card.layer.borderColor = Theme.text.withAlphaComponent(0.15).cgColor
        card.layer.cornerRadius = 24
        card.addSubview(stack)
        // Constants are set in `applyMetrics()`; each is card edge to stack edge, inward.
        setupCardInsets = [
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            card.bottomAnchor.constraint(equalTo: stack.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: stack.trailingAnchor)
        ]
        NSLayoutConstraint.activate(setupCardInsets)
        return card
    }

    private static func makeSectionLabel(_ text: String) -> UILabel {
        let label = makeLabel(size: 13, weight: .heavy)
        label.text = text
        label.textAlignment = .natural
        label.textColor = Theme.text.withAlphaComponent(0.65)
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
        highScoreLabel.text = "🏆 Best: \(best)"
    }

    func showPlayfieldNote(_ text: String?) {
        playfieldNoteLabel.text = text
        playfieldNoteLabel.isHidden = text == nil
    }

    func showProfile(name: String, face: CatFace, favorite: String?) {
        profileButton.configuration?.title = name
        profileButton.configuration?.subtitle = favorite
        profileButton.configuration?.image = face.image(side: Theme.scaled(34))
        profileButton.accessibilityLabel = [name, face.title, favorite]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

@available(iOS 17.0, *)
#Preview {
    HomeRouter.createModule()
}
