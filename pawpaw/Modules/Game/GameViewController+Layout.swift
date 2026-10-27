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
        // Big enough for a thumb on a phone and for an owner's hand on an iPad.
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

    /// Cats tap and brush the screen all the time, so leaving the game needs a deliberate hold.
    func installHoldToExit(on button: UIButton) {
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(holdToExitChanged(_:)))
        hold.minimumPressDuration = 1.5
        button.addGestureRecognizer(hold)
        button.accessibilityHint = "Press and hold to leave the game"
        // A quick tap does nothing, so tell the owner how to leave.
        button.addTarget(self, action: #selector(showExitHint), for: .touchUpInside)
    }

    /// Short message for owners who tap an exit button instead of holding it.
    @objc func showExitHint() {
        let tag = 9_001
        view.viewWithTag(tag)?.removeFromSuperview()

        var config = UIButton.Configuration.filled()
        config.title = "Press and hold for 1.5 seconds to leave"
        config.baseBackgroundColor = Theme.panel
        config.baseForegroundColor = Theme.text
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18)
        config.titleAlignment = .center
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.roundedFont(size: Theme.scaled(16), weight: .bold)
            return outgoing
        }
        let hint = UIButton(configuration: config)
        hint.tag = tag
        hint.isUserInteractionEnabled = false
        hint.alpha = 0
        hint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hint)
        NSLayoutConstraint.activate([
            hint.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hint.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            // Wraps onto two lines on narrow phones instead of running off the screen.
            hint.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            hint.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
        UIView.animate(withDuration: 0.2, animations: { hint.alpha = 1 }, completion: { _ in
            UIView.animate(withDuration: 0.4, delay: 2.0, options: [], animations: { hint.alpha = 0 }, completion: { _ in
                hint.removeFromSuperview()
            })
        })
    }

    @objc func holdToExitChanged(_ gesture: UILongPressGestureRecognizer) {
        // `.began` fires only after the full hold duration has passed.
        guard gesture.state == .began else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        homeTapped()
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

        resultTitleLabel.font = Theme.roundedFont(size: Theme.scaled(34))
        resultTitleLabel.textColor = Theme.text
        resultTitleLabel.textAlignment = .center
        resultTitleLabel.numberOfLines = 0

        resultDetailsLabel.font = Theme.roundedFont(size: Theme.scaled(20), weight: .semibold)
        resultDetailsLabel.textColor = Theme.text
        resultDetailsLabel.textAlignment = .center
        resultDetailsLabel.numberOfLines = 0

        var againConfig = UIButton.Configuration.filled()
        againConfig.title = "Play Again"
        againConfig.baseBackgroundColor = Theme.accent
        againConfig.baseForegroundColor = .white
        againConfig.cornerStyle = .capsule
        againConfig.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 36, bottom: 14, trailing: 36)
        againConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.roundedFont(size: Theme.scaled(20), weight: .bold)
            return outgoing
        }
        let againButton = UIButton(configuration: againConfig)
        againButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.minimumTapSize).isActive = true
        againButton.accessibilityIdentifier = "playAgainButton"
        againButton.addTarget(self, action: #selector(playAgainTapped), for: .touchUpInside)

        var menuConfig = UIButton.Configuration.plain()
        menuConfig.title = "Hold to go Home"
        menuConfig.baseForegroundColor = Theme.text
        menuConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        menuConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.roundedFont(size: Theme.scaled(17), weight: .bold)
            return outgoing
        }
        let menuButton = UIButton(configuration: menuConfig)
        menuButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.minimumTapSize).isActive = true
        menuButton.accessibilityIdentifier = "resultHomeButton"
        installHoldToExit(on: menuButton)

        let stack = UIStackView(arrangedSubviews: [resultTitleLabel, resultDetailsLabel, againButton, menuButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        // The card scrolls if a small phone in landscape can't fit it, so the exit buttons stay reachable.
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
