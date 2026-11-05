//
//  GameViewController+Layout.swift
//  pawpaw
//

import SpriteKit
import UIKit

extension GameViewController {
    func setupGameArea() {
        gameArea.allowsTransparency = true
        gameArea.backgroundColor = .clear
        gameArea.isMultipleTouchEnabled = true
        gameArea.ignoresSiblingOrder = true
        // Cats track motion closely and notice flicker above 60 Hz, so ask ProMotion screens for 120 Hz.
        gameArea.preferredFramesPerSecond = 120
        gameArea.presentScene(scene)
        gameArea.translatesAutoresizingMaskIntoConstraints = false
        // Behind the HUD, which is added later, so taps on the home button still reach it.
        view.addSubview(gameArea)
        view.addLayoutGuide(playfieldGuide)
        // The scene fills the screen so critters run off the top edge, not into the HUD's strip.
        // `playfieldGuide` marks the field below the HUD, where they spawn, stop and hide.
        NSLayoutConstraint.activate([
            gameArea.topAnchor.constraint(equalTo: view.topAnchor),
            gameArea.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gameArea.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gameArea.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            playfieldGuide.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 16 + max(48, Theme.scaled(48))),
            playfieldGuide.leadingAnchor.constraint(equalTo: gameArea.leadingAnchor),
            playfieldGuide.trailingAnchor.constraint(equalTo: gameArea.trailingAnchor),
            playfieldGuide.bottomAnchor.constraint(equalTo: gameArea.bottomAnchor),
        ])
    }

    /// Tells the scene how much of its top sits under the HUD.
    func updatePlayfieldInset() {
        scene.topInset = max(playfieldGuide.layoutFrame.minY - gameArea.frame.minY, 0)
    }

    func setupHUD() {
        var homeConfig = UIButton.Configuration.plain()
        homeConfig.image = UIImage(systemName: "house.fill")
        homeConfig.baseForegroundColor = Theme.text
        homeConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: Theme.scaled(20), weight: .semibold
        )
        homeConfig.contentInsets = NSDirectionalEdgeInsets(
            top: 10, leading: 10, bottom: 10, trailing: 10)
        let homeButton = UIButton(configuration: homeConfig)
        homeButton.accessibilityIdentifier = "homeButton"
        homeButton.accessibilityLabel = "Home"
        installHoldToExit(on: homeButton)
        hudHomeButton = homeButton
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
            hud.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            hud.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            hud.heightAnchor.constraint(equalToConstant: max(48, Theme.scaled(48))),
        ])
    }

    /// Leaving needs a deliberate hold; a plain tap only shows a hint.
    func installHoldToExit(on button: UIButton) {
        button.addHoldToConfirm(self, action: #selector(holdToExitChanged(_:)))
        button.accessibilityHint = "Press and hold to leave the game"
        button.addTarget(self, action: #selector(showExitHint), for: .touchUpInside)
    }

    @objc func showExitHint() {
        showHoldHint("Press and hold to leave")
    }

    @objc func holdToExitChanged(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        presenter?.didTapHome()
    }

    func setupResultOverlay() {
        // Only a light tint: the field around the card stays in play for the lure.
        resultOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        resultOverlay.isHidden = true
        resultOverlay.translatesAutoresizingMaskIntoConstraints = false
        resultOverlay.accessibilityViewIsModal = true
        view.addSubview(resultOverlay)

        let card = UIView()
        Theme.styleCard(card)
        resultOverlay.interactiveView = card
        resultCard = card

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

        let againButton = Theme.filledButton(title: "Hold to Play Again")
        againButton.accessibilityIdentifier = "playAgainButton"
        againButton.accessibilityHint = "Press and hold to start another round"
        againButton.addHoldToConfirm(self, action: #selector(playAgainHeld(_:)))
        againButton.addTarget(self, action: #selector(showPlayAgainHint), for: .touchUpInside)

        let menuButton = Theme.plainButton(
            title: "Hold to go Home", fontSize: 17, foreground: Theme.text)
        menuButton.accessibilityIdentifier = "resultHomeButton"
        installHoldToExit(on: menuButton)

        let stack = UIStackView(arrangedSubviews: [
            resultTitleLabel, resultDetailsLabel, againButton, menuButton,
        ])
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
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -28),
        ])
    }
}
