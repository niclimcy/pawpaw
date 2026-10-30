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

    private let subtitleLabel: UILabel = {
        let label = HomeViewController.makeLabel(size: 18, weight: .semibold)
        label.text = "Catch the mice, bugs and butterflies!"
        return label
    }()

    private let profileButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = CatProfile.defaultName
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = Theme.text
        config.baseForegroundColor = Theme.text
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 10,
            leading: 20,
            bottom: 10,
            trailing: 20
        )
        config.titleTextAttributesTransformer = Theme.fontTransformer(
            size: 20,
            weight: .bold
        )
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(
            greaterThanOrEqualToConstant: Theme.minimumTapSize
        ).isActive = true
        button.accessibilityIdentifier = "profileButton"
        button.accessibilityHint = "Opens the list of cats"
        return button
    }()

    private let favoriteLabel: UILabel = {
        let label = HomeViewController.makeLabel(size: 16, weight: .semibold)
        label.textColor = Theme.text.withAlphaComponent(0.85)
        label.isHidden = true
        return label
    }()

    private let highScoreLabel: UILabel = {
        let label = HomeViewController.makeLabel(size: 22, weight: .bold)
        label.text = "Best: 0"
        return label
    }()

    private let ownerNoteLabel: UILabel = {
        let label = HomeViewController.makeLabel(size: 14, weight: .semibold)
        label.text =
            "For owners: during play, press and hold the home button to leave the game."
        label.textColor = Theme.text.withAlphaComponent(0.75)
        return label
    }()

    private static let modeFontSize: CGFloat = 16
    private static let themeFontSize: CGFloat = 14

    private let modeControl: UISegmentedControl = {
        let control = UISegmentedControl(
            items: SessionMode.allCases.map(\.title)
        )
        Theme.styleSegmented(control, fontSize: HomeViewController.modeFontSize)
        control.accessibilityIdentifier = "modeControl"
        control.accessibilityLabel = "Session length"
        return control
    }()

    private let themeControl: UISegmentedControl = {
        let control = UISegmentedControl(
            items: PlayfieldTheme.allCases.map(\.title)
        )
        Theme.styleSegmented(
            control,
            fontSize: HomeViewController.themeFontSize
        )
        control.accessibilityIdentifier = "themeControl"
        control.accessibilityLabel = "Background"
        return control
    }()

    private let statsButton: UIButton = {
        let button = Theme.plainButton(
            title: "Hold for Stats",
            image: "chart.bar.fill",
            foreground: Theme.text.withAlphaComponent(0.85)
        )
        button.accessibilityIdentifier = "statsButton"
        button.accessibilityHint = "Press and hold to open play statistics"
        return button
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
        modeControl.addTarget(
            self,
            action: #selector(modeChanged),
            for: .valueChanged
        )
        themeControl.addTarget(
            self,
            action: #selector(themeChanged),
            for: .valueChanged
        )
        statsButton.addGestureRecognizer(
            UILongPressGestureRecognizer.holdToConfirm(
                self,
                #selector(statsHeld(_:))
            )
        )
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
        Theme.applySegmentedFonts(to: modeControl, fontSize: Self.modeFontSize)
        Theme.applySegmentedFonts(
            to: themeControl,
            fontSize: Self.themeFontSize
        )
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [
            logoView, titleLabel, subtitleLabel, profileButton, favoriteLabel,
            modeControl, themeControl,
            highScoreLabel, playButton, statsButton, ownerNoteLabel,
        ])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Theme.scaled(16)
        stack.setCustomSpacing(Theme.scaled(28), after: highScoreLabel)
        stack.setCustomSpacing(Theme.scaled(20), after: statsButton)

        for wide in [
            modeControl, themeControl, subtitleLabel, favoriteLabel,
            ownerNoteLabel,
        ] {
            wide.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive =
                true
        }

        embedCentered(stack, maxWidth: 520)
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

    @objc private func statsHeld(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        presenter?.didRequestStats()
    }

    @objc private func themeChanged() {
        presenter?.didSelectTheme(
            PlayfieldTheme.allCases[themeControl.selectedSegmentIndex]
        )
    }

    // MARK: HomeViewProtocol
    func showMode(_ mode: SessionMode) {
        modeControl.selectedSegmentIndex =
            SessionMode.allCases.firstIndex(of: mode) ?? 0
    }

    func showTheme(_ theme: PlayfieldTheme) {
        themeControl.selectedSegmentIndex =
            PlayfieldTheme.allCases.firstIndex(of: theme) ?? 0
        guard theme != shownTheme else { return }
        shownTheme = theme
        installBackground(theme: theme)
    }

    func showHighScore(_ score: Int?) {
        highScoreLabel.isHidden = score == nil
        highScoreLabel.text = "Best: \(score ?? 0)"
    }

    func showProfile(name: String, face: CatFace, favorite: String?) {
        profileButton.configuration?.title = name
        profileButton.configuration?.image = face.image(side: Theme.scaled(34))
        profileButton.accessibilityLabel =
            "\(name), \(face.title). Opens the list of cats"
        favoriteLabel.text = favorite
        favoriteLabel.isHidden = favorite == nil
    }
}

@available(iOS 17.0, *)
#Preview {
    HomeRouter.createModule()
}
