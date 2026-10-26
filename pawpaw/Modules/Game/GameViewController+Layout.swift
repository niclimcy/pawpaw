//
//  GameViewController+Layout.swift
//  pawpaw
//

import UIKit

extension GameViewController {
    func setupGameArea() {
        gameArea.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gameArea)
        NSLayoutConstraint.activate([
            gameArea.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),
            gameArea.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gameArea.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gameArea.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func setupHUD() {
        var homeConfig = UIButton.Configuration.plain()
        homeConfig.image = UIImage(systemName: "house.fill")
        homeConfig.baseForegroundColor = Theme.text
        let homeButton = UIButton(configuration: homeConfig)
        homeButton.accessibilityIdentifier = "homeButton"
        homeButton.addTarget(self, action: #selector(homeTapped), for: .touchUpInside)
        homeButton.setContentHuggingPriority(.required, for: .horizontal)

        let hud = UIStackView(arrangedSubviews: [homeButton, scoreLabel, timeLabel])
        hud.axis = .horizontal
        hud.alignment = .center
        hud.spacing = 12
        hud.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hud)

        NSLayoutConstraint.activate([
            hud.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            hud.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            hud.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            hud.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    func setupResultOverlay() {
        resultOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        resultOverlay.isHidden = true
        resultOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultOverlay)

        let card = UIView()
        card.backgroundColor = Theme.panel
        card.layer.borderWidth = 3
        card.layer.borderColor = Theme.gold.withAlphaComponent(0.6).cgColor
        card.layer.cornerRadius = 28
        card.translatesAutoresizingMaskIntoConstraints = false
        resultOverlay.addSubview(card)

        resultTitleLabel.font = Theme.roundedFont(size: 38)
        resultTitleLabel.textColor = Theme.text
        resultTitleLabel.textAlignment = .center

        resultDetailsLabel.font = Theme.roundedFont(size: 22, weight: .semibold)
        resultDetailsLabel.textColor = Theme.text
        resultDetailsLabel.textAlignment = .center
        resultDetailsLabel.numberOfLines = 0

        var againConfig = UIButton.Configuration.filled()
        againConfig.title = "Play Again"
        againConfig.baseBackgroundColor = Theme.accent
        againConfig.baseForegroundColor = .white
        againConfig.cornerStyle = .capsule
        againConfig.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 36, bottom: 14, trailing: 36)
        let againButton = UIButton(configuration: againConfig)
        againButton.accessibilityIdentifier = "playAgainButton"
        againButton.addTarget(self, action: #selector(playAgainTapped), for: .touchUpInside)

        var menuConfig = UIButton.Configuration.plain()
        menuConfig.title = "Home"
        menuConfig.baseForegroundColor = Theme.text
        let menuButton = UIButton(configuration: menuConfig)
        menuButton.accessibilityIdentifier = "resultHomeButton"
        menuButton.addTarget(self, action: #selector(homeTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [resultTitleLabel, resultDetailsLabel, againButton, menuButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            resultOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            resultOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            resultOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            card.centerXAnchor.constraint(equalTo: resultOverlay.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: resultOverlay.centerYAnchor),
            card.widthAnchor.constraint(lessThanOrEqualToConstant: 360),
            card.leadingAnchor.constraint(greaterThanOrEqualTo: resultOverlay.leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(lessThanOrEqualTo: resultOverlay.trailingAnchor, constant: -24),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -28)
        ])
    }
}
