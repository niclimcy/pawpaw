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
            gameArea.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16 + max(48, Theme.scaled(48))),
            gameArea.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gameArea.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gameArea.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func setupHUD() {
        var homeConfig = UIButton.Configuration.plain()
        homeConfig.image = UIImage(systemName: "house.fill")
        homeConfig.baseForegroundColor = Theme.text
        homeConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: Theme.scaled(20), weight: .semibold
        )
        homeConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        let homeButton = UIButton(configuration: homeConfig)
        homeButton.accessibilityIdentifier = "homeButton"
        homeButton.accessibilityLabel = "Home"
        installHoldToExit(on: homeButton)
        homeButton.setContentHuggingPriority(.required, for: .horizontal)
        let side = max(Theme.minimumTapSize, Theme.scaled(48))
        homeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: side).isActive = true
        homeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: side).isActive = true

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
            hud.heightAnchor.constraint(equalToConstant: max(48, Theme.scaled(48)))
        ])
    }

    /// Leaving needs a deliberate hold; a plain tap only shows a hint.
    func installHoldToExit(on button: UIButton) {
        button.addGestureRecognizer(UILongPressGestureRecognizer.holdToConfirm(self, #selector(holdToExitChanged(_:))))
        button.accessibilityHint = "Press and hold to leave the game"
        button.addTarget(self, action: #selector(showExitHint), for: .touchUpInside)
    }

    @objc func showExitHint() {
        let tag = 9_001
        view.viewWithTag(tag)?.removeFromSuperview()

        let message = "Press and hold to leave"
        let hint = Theme.filledButton(
            title: message,
            fontSize: 16,
            background: Theme.panel,
            foreground: Theme.text,
            insets: NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18)
        )
        hint.configuration?.titleAlignment = .center
        hint.tag = tag
        hint.isUserInteractionEnabled = false
        hint.alpha = 0
        hint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hint)
        NSLayoutConstraint.activate([
            hint.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hint.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            hint.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            hint.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
        UIAccessibility.post(notification: .announcement, argument: message)
        UIView.animate(withDuration: 0.2, animations: { hint.alpha = 1 }, completion: { _ in
            UIView.animate(withDuration: 0.4, delay: 2.0, options: [], animations: { hint.alpha = 0 }, completion: { _ in
                hint.removeFromSuperview()
            })
        })
    }

    @objc func holdToExitChanged(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        presenter?.didTapHome()
    }

    func setupResultOverlay() {
        resultOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        resultOverlay.isHidden = true
        resultOverlay.translatesAutoresizingMaskIntoConstraints = false
        resultOverlay.accessibilityViewIsModal = true
        view.addSubview(resultOverlay)

        let card = UIView()
        Theme.styleCard(card)

        resultTitleLabel.font = Theme.roundedFont(size: Theme.scaled(34))
        resultTitleLabel.adjustsFontForContentSizeCategory = true
        resultTitleLabel.textColor = Theme.text
        resultTitleLabel.textAlignment = .center
        resultTitleLabel.numberOfLines = 0
        resultTitleLabel.accessibilityTraits = .header

        resultDetailsLabel.font = Theme.roundedFont(size: Theme.scaled(20), weight: .semibold)
        resultDetailsLabel.adjustsFontForContentSizeCategory = true
        resultDetailsLabel.textColor = Theme.text
        resultDetailsLabel.textAlignment = .center
        resultDetailsLabel.numberOfLines = 0

        let againButton = Theme.filledButton(title: "Play Again")
        againButton.accessibilityIdentifier = "playAgainButton"
        againButton.addTarget(self, action: #selector(playAgainTapped), for: .touchUpInside)

        let menuButton = Theme.plainButton(title: "Hold to go Home", fontSize: 17, foreground: Theme.text)
        menuButton.accessibilityIdentifier = "resultHomeButton"
        installHoldToExit(on: menuButton)

        let stack = UIStackView(arrangedSubviews: [resultTitleLabel, resultDetailsLabel, againButton, menuButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        embedCentered(card, maxWidth: Theme.scaled(380), in: resultOverlay)

        NSLayoutConstraint.activate([
            resultOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            resultOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            resultOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -28)
        ])
    }
}
