//
//  OnboardingViewController+Practice.swift
//  pawpaw
//

import UIKit

extension OnboardingViewController {
    func setupAmbient() {
        ambient.translatesAutoresizingMaskIntoConstraints = false
        // Above the background, below everything else.
        view.insertSubview(ambient, at: 1)
        NSLayoutConstraint.activate([
            ambient.topAnchor.constraint(equalTo: view.topAnchor),
            ambient.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ambient.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ambient.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func setupPractice() {
        playfield.nextTarget = { [weak self] in self?.presenter?.nextPracticeTarget() }
        playfield.onCatch = { [weak self] in self?.presenter?.didCatchPracticeCritter() }
        holdPractice.onTap = { [weak self] in self?.presenter?.didTapHousePractice() }
        holdPractice.onHold = { [weak self] in self?.presenter?.didCompleteHoldPractice() }

        for practice in [playfield, countdown, holdPractice] as [UIView] {
            practice.isHidden = true
            practice.translatesAutoresizingMaskIntoConstraints = false
            practiceArea.addSubview(practice)
            NSLayoutConstraint.activate([
                practice.topAnchor.constraint(equalTo: practiceArea.topAnchor),
                practice.bottomAnchor.constraint(equalTo: practiceArea.bottomAnchor),
                practice.leadingAnchor.constraint(equalTo: practiceArea.leadingAnchor),
                practice.trailingAnchor.constraint(equalTo: practiceArea.trailingAnchor),
            ])
        }
        // Gives way before the text, but not below a usable size.
        let preferred = practiceArea.heightAnchor.constraint(
            equalToConstant: Self.practiceHeight)
        preferred.priority = Self.artPriority
        NSLayoutConstraint.activate([
            preferred,
            practiceArea.heightAnchor.constraint(
                greaterThanOrEqualToConstant: Self.minPracticeHeight),
        ])
    }

    /// `nil` shows the cat art row instead.
    func showPractice(_ interaction: OnboardingInteraction?) {
        playfield.isHidden = interaction != .catchCritter
        countdown.isHidden = interaction != .countdown
        holdPractice.isHidden = interaction != .holdToLeave
        practiceArea.isHidden = interaction == nil
        artRow.isHidden = interaction != nil
    }

    func startInteraction() {
        guard viewIfLoaded?.window != nil else { return }
        switch interaction {
        case .catchCritter: playfield.start()
        case .countdown: countdown.start()
        case .holdToLeave, nil: break
        }
    }

    func stopInteractions() {
        playfield.stop()
        countdown.stop()
    }

    func bounce(_ target: UIView) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        target.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
        UIView.animate(
            withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.4,
            initialSpringVelocity: 0.8, options: [.allowUserInteraction]
        ) {
            target.transform = .identity
        }
    }

    func burstPawPrints(from rect: CGRect) {
        let origin = CGPoint(x: rect.midX, y: rect.midY)
        let symbol = UIImage.SymbolConfiguration(pointSize: 26, weight: .bold)
        for index in 0..<10 {
            let paw = UIImageView(
                image: UIImage(systemName: "pawprint.fill", withConfiguration: symbol))
            paw.tintColor = index.isMultiple(of: 2) ? Theme.gold : Theme.accent
            paw.center = origin
            paw.isUserInteractionEnabled = false
            view.addSubview(paw)
            let angle = CGFloat(index) / 10 * 2 * .pi + .random(in: -0.2...0.2)
            let distance = CGFloat.random(in: 90...170)
            let delta = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)
            paw.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            UIView.animate(withDuration: 0.65, delay: 0, options: [.curveEaseOut]) {
                paw.center = CGPoint(x: origin.x + delta.x, y: origin.y + delta.y)
                paw.transform = CGAffineTransform(rotationAngle: angle + .pi / 2)
                paw.alpha = 0
            } completion: { _ in
                paw.removeFromSuperview()
            }
        }
    }
}
