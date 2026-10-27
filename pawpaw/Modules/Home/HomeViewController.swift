//
//  HomeViewController.swift
//  pawpaw
//

import UIKit

final class HomeViewController: UIViewController, HomeViewProtocol {
    var presenter: HomePresenterProtocol?
    private var shownTheme: PlayfieldTheme = .wood

    private let logoLabel: UILabel = {
        let label = UILabel()
        label.text = "🐾"
        label.font = .systemFont(ofSize: Theme.scaled(90))
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Paw Paw"
        label.font = Theme.roundedFont(size: Theme.scaled(48))
        label.textColor = Theme.text
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Catch the mice, bugs and butterflies!"
        label.font = Theme.roundedFont(size: Theme.scaled(18), weight: .semibold)
        label.textColor = Theme.text
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    /// The cat that is playing. Tapping it opens the profiles screen.
    private let profileButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = CatProfile.defaultName
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = Theme.text
        config.baseForegroundColor = Theme.text
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.roundedFont(size: Theme.scaled(20), weight: .bold)
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.minimumTapSize).isActive = true
        button.accessibilityIdentifier = "profileButton"
        button.accessibilityHint = "Opens the list of cats"
        return button
    }()

    /// "Luna loves butterflies", shown once the cat has caught something.
    private let favoriteLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.roundedFont(size: Theme.scaled(16), weight: .semibold)
        label.textColor = Theme.text.withAlphaComponent(0.85)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private let highScoreLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.roundedFont(size: Theme.scaled(22), weight: .bold)
        label.textColor = Theme.text
        label.textAlignment = .center
        label.text = "Best: 0"
        return label
    }()

    /// A note for the human: cats can't leave the game by accident.
    private let ownerNoteLabel: UILabel = {
        let label = UILabel()
        label.text = "For owners: during play, press and hold the home button for 1.5 seconds to leave the game."
        label.font = Theme.roundedFont(size: Theme.scaled(14), weight: .semibold)
        label.textColor = Theme.text.withAlphaComponent(0.75)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    /// Short rounds suit kittens and seniors; relaxed play has no timer at all.
    private let modeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: SessionMode.allCases.map(\.title))
        Theme.styleSegmented(control, fontSize: 16)
        control.accessibilityIdentifier = "modeControl"
        return control
    }()

    /// Picks the playfield background; the Home screen previews the choice.
    private let themeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: PlayfieldTheme.allCases.map(\.title))
        Theme.styleSegmented(control, fontSize: 14)
        control.accessibilityIdentifier = "themeControl"
        return control
    }()

    /// Owners only: a press-and-hold keeps paws out of the stats screen.
    private let statsButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Hold for Stats"
        config.image = UIImage(systemName: "chart.bar.fill")
        config.imagePadding = 6
        config.baseForegroundColor = Theme.text.withAlphaComponent(0.85)
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.roundedFont(size: Theme.scaled(16), weight: .bold)
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.minimumTapSize).isActive = true
        button.accessibilityIdentifier = "statsButton"
        button.accessibilityHint = "Press and hold to open play statistics"
        return button
    }()

    private let playButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "PLAY"
        config.baseBackgroundColor = Theme.accent
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(
            top: Theme.scaled(20), leading: Theme.scaled(56), bottom: Theme.scaled(20), trailing: Theme.scaled(56)
        )
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.roundedFont(size: Theme.scaled(34))
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.accessibilityIdentifier = "playButton"
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        installBackground(theme: .wood)
        setupLayout()
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        profileButton.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
        modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        themeControl.addTarget(self, action: #selector(themeChanged), for: .valueChanged)
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(statsHeld(_:)))
        hold.minimumPressDuration = 1.5
        statsButton.addGestureRecognizer(hold)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.viewWillAppear()
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [
            logoLabel, titleLabel, subtitleLabel, profileButton, favoriteLabel, modeControl, themeControl,
            highScoreLabel, playButton, statsButton, ownerNoteLabel
        ])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Theme.scaled(16)
        stack.setCustomSpacing(Theme.scaled(28), after: highScoreLabel)
        stack.setCustomSpacing(Theme.scaled(20), after: statsButton)

        // The pickers and the note use the full column width; everything else stays centered.
        for wide in [modeControl, themeControl, ownerNoteLabel] {
            wide.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }

        // Everything lives in one centered column that scrolls on small screens and is capped on iPad.
        embedCentered(stack, maxWidth: 520)
    }

    @objc private func playTapped() {
        presenter?.didTapPlay()
    }

    @objc private func profileTapped() {
        presenter?.didTapProfile()
    }

    @objc private func modeChanged() {
        presenter?.didSelectMode(SessionMode.allCases[modeControl.selectedSegmentIndex])
    }

    @objc private func statsHeld(_ gesture: UILongPressGestureRecognizer) {
        // `.began` fires only after the full hold duration has passed.
        guard gesture.state == .began else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        presenter?.didRequestStats()
    }

    @objc private func themeChanged() {
        presenter?.didSelectTheme(PlayfieldTheme.allCases[themeControl.selectedSegmentIndex])
    }

    // MARK: HomeViewProtocol
    func showMode(_ mode: SessionMode) {
        modeControl.selectedSegmentIndex = SessionMode.allCases.firstIndex(of: mode) ?? 0
    }

    func showTheme(_ theme: PlayfieldTheme) {
        themeControl.selectedSegmentIndex = PlayfieldTheme.allCases.firstIndex(of: theme) ?? 0
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
        profileButton.configuration?.imagePlacement = .leading
        profileButton.accessibilityLabel = "\(name), \(face.title). Opens the list of cats"
        favoriteLabel.text = favorite
        favoriteLabel.isHidden = favorite == nil
    }
}

@available(iOS 17.0, *)
#Preview {
    HomeRouter.createModule()
}
