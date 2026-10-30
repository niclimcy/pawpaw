//
//  HomeViewController.swift
//  pawpaw
//

import UIKit

final class HomeViewController: UIViewController, HomeViewProtocol {
    var presenter: HomePresenterProtocol?
    private var shownTheme: PlayfieldTheme = .wood

    private let logoView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "logo_paw"))
        view.contentMode = .scaleAspectFit
        let height = Theme.scaled(80)
        let aspect = view.image.map { $0.size.width / $0.size.height } ?? 1
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        view.widthAnchor.constraint(equalToConstant: height * aspect).isActive =
            true
        view.isAccessibilityElement = false
        return view
    }()

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
        Theme.applySegmentedFonts(
            to: modeControl,
            fontSize: Self.modeFontSize,
            selectedText: Self.selectedText
        )
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
        let stack = UIStackView(arrangedSubviews: [
            logoView, titleLabel, setupCard, playButton, highScoreLabel,
        ])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Theme.scaled(12)
        stack.setCustomSpacing(Theme.scaled(28), after: titleLabel)
        stack.setCustomSpacing(Theme.scaled(28), after: setupCard)
        setupCard.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        embedCentered(stack, maxWidth: Self.maxContentWidth, in: content)
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
        let stack = UIStackView(arrangedSubviews: [
            Self.makeSectionLabel("ROUND LENGTH"), modeControl,
            Self.makeSectionLabel("PLAYGROUND"), themePicker,
        ])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8
        stack.setCustomSpacing(Theme.scaled(20), after: modeControl)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let card = UIView()
        Theme.styleCard(card)
        card.backgroundColor = Theme.panel.withAlphaComponent(0.85)
        card.layer.borderWidth = 2
        card.layer.borderColor = Theme.text.withAlphaComponent(0.15).cgColor
        card.layer.cornerRadius = 24
        card.addSubview(stack)
        let inset = Theme.scaled(18)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: inset),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -inset),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: inset),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -inset)
        ])
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

    @objc private func statsTapped() {
        presenter?.didRequestStats()
    }

    // MARK: HomeViewProtocol
    func showMode(_ mode: SessionMode) {
        modeControl.selectedSegmentIndex =
            SessionMode.allCases.firstIndex(of: mode) ?? 0
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
