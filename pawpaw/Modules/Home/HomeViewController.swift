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
        label.font = .systemFont(ofSize: 110)
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Paw Paw"
        label.font = Theme.roundedFont(size: 52)
        label.textColor = Theme.text
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Catch the mice, bugs and butterflies!"
        label.font = Theme.roundedFont(size: 18, weight: .semibold)
        label.textColor = Theme.text
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let highScoreLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.roundedFont(size: 22, weight: .bold)
        label.textColor = Theme.text
        label.textAlignment = .center
        label.text = "Best: 0"
        return label
    }()

    /// A note for the human: cats can't leave the game by accident.
    private let ownerNoteLabel: UILabel = {
        let label = UILabel()
        label.text = "For owners: during play, press and hold the home button for 1.5 seconds to leave the game."
        label.font = Theme.roundedFont(size: 14, weight: .semibold)
        label.textColor = Theme.text.withAlphaComponent(0.75)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    /// Short rounds suit kittens and seniors; relaxed play has no timer at all.
    private let modeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: SessionMode.allCases.map(\.title))
        control.selectedSegmentTintColor = Theme.accent
        control.backgroundColor = Theme.panel
        control.setTitleTextAttributes([
            .foregroundColor: Theme.text,
            .font: Theme.roundedFont(size: 16, weight: .bold)
        ], for: .normal)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: Theme.roundedFont(size: 16, weight: .bold)
        ], for: .selected)
        control.accessibilityIdentifier = "modeControl"
        return control
    }()

    /// Picks the playfield background; the Home screen previews the choice.
    private let themeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: PlayfieldTheme.allCases.map(\.title))
        control.selectedSegmentTintColor = Theme.accent
        control.backgroundColor = Theme.panel
        control.setTitleTextAttributes([
            .foregroundColor: Theme.text,
            .font: Theme.roundedFont(size: 14, weight: .bold)
        ], for: .normal)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: Theme.roundedFont(size: 14, weight: .bold)
        ], for: .selected)
        control.accessibilityIdentifier = "themeControl"
        return control
    }()

    private let playButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "PLAY"
        config.baseBackgroundColor = Theme.accent
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 22, leading: 70, bottom: 22, trailing: 70)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.roundedFont(size: 34)
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
        modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        themeControl.addTarget(self, action: #selector(themeChanged), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.viewWillAppear()
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [logoLabel, titleLabel, subtitleLabel, modeControl, themeControl, highScoreLabel, playButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 18
        stack.setCustomSpacing(36, after: highScoreLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        ownerNoteLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ownerNoteLabel)

        NSLayoutConstraint.activate([
            ownerNoteLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            ownerNoteLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            ownerNoteLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
        ])
    }

    @objc private func playTapped() {
        presenter?.didTapPlay()
    }

    @objc private func modeChanged() {
        presenter?.didSelectMode(SessionMode.allCases[modeControl.selectedSegmentIndex])
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
}

#Preview {
    HomeRouter.createModule()
}
