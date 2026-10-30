//
//  GameViewController+Countdown.swift
//  pawpaw
//

import UIKit

struct PendingCountdown {
    let showsExitTip: Bool
    let completion: () -> Void
}

extension GameViewController {
    private static let countdownTag = 9_003
    private static let countdownFrom = 3
    private static let stepDuration: TimeInterval = 0.8

    /// The overlay ignores touches so the house button still works.
    func showGetReady(showsExitTip: Bool, completion: @escaping () -> Void) {
        removeCountdownOverlay(animated: false)
        countdownGeneration += 1
        pendingCountdown = PendingCountdown(showsExitTip: showsExitTip, completion: completion)

        let overlay = UIView()
        overlay.tag = Self.countdownTag
        overlay.isUserInteractionEnabled = false
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let numberLabel = installCountdownLabels(in: overlay)
        if showsExitTip {
            installExitTip(in: overlay)
        }

        let announcement = showsExitTip ? "Get ready. Owners: press and hold Home to leave." : "Get ready."
        UIAccessibility.post(notification: .announcement, argument: announcement)
        runCountdownStep(Self.countdownFrom, label: numberLabel, generation: countdownGeneration)
    }

    /// Keeps the countdown pending so it restarts when the app is active again.
    func interruptCountdown() {
        guard pendingCountdown != nil else { return }
        countdownGeneration += 1
        removeCountdownOverlay(animated: false)
    }

    func cancelCountdown() {
        countdownGeneration += 1
        pendingCountdown = nil
        removeCountdownOverlay(animated: false)
    }

    private func runCountdownStep(_ number: Int, label: UILabel, generation: Int) {
        guard generation == countdownGeneration else { return }
        guard number > 0 else {
            let completion = pendingCountdown?.completion
            pendingCountdown = nil
            removeCountdownOverlay(animated: true)
            completion?()
            return
        }

        label.text = "\(number)"
        if UIAccessibility.isReduceMotionEnabled {
            label.alpha = 1
        } else {
            label.alpha = 0
            label.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
                label.alpha = 1
                label.transform = .identity
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.stepDuration) { [weak self, weak label] in
            guard let self, let label else { return }
            self.runCountdownStep(number - 1, label: label, generation: generation)
        }
    }

    private func removeCountdownOverlay(animated: Bool) {
        guard let overlay = view.viewWithTag(Self.countdownTag) else { return }
        overlay.tag = 0
        guard animated else {
            overlay.removeFromSuperview()
            return
        }
        UIView.animate(withDuration: 0.2, animations: { overlay.alpha = 0 }, completion: { _ in
            overlay.removeFromSuperview()
        })
    }

    private func installCountdownLabels(in overlay: UIView) -> UILabel {
        let readyLabel = UILabel()
        readyLabel.text = "Get ready!"
        readyLabel.font = Theme.roundedFont(size: Theme.scaled(26))
        readyLabel.textColor = Theme.text

        let numberLabel = UILabel()
        numberLabel.font = Theme.roundedFont(size: Theme.scaled(110))
        numberLabel.textColor = Theme.accent
        numberLabel.isAccessibilityElement = false

        for label in [readyLabel, numberLabel] {
            label.textAlignment = .center
            label.adjustsFontForContentSizeCategory = true
            label.layer.shadowColor = UIColor.black.cgColor
            label.layer.shadowOpacity = 0.5
            label.layer.shadowRadius = 6
            label.layer.shadowOffset = .zero
        }

        let stack = UIStackView(arrangedSubviews: [readyLabel, numberLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: gameArea.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: gameArea.centerYAnchor)
        ])
        return numberLabel
    }
}
