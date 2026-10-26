//
//  HomeViewController.swift
//  pawpaw
//

import UIKit

final class HomeViewController: UIViewController, HomeViewProtocol {
    var presenter: HomePresenterProtocol?

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
        installWoodBackground()
        setupLayout()
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.viewWillAppear()
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [logoLabel, titleLabel, subtitleLabel, highScoreLabel, playButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 18
        stack.setCustomSpacing(36, after: highScoreLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
        ])
    }

    @objc private func playTapped() {
        presenter?.didTapPlay()
    }

    // MARK: HomeViewProtocol
    func showHighScore(_ score: Int) {
        highScoreLabel.text = "Best: \(score)"
    }
}

#Preview {
    HomeRouter.createModule()
}
