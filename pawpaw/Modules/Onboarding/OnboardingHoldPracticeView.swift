//
//  OnboardingHoldPracticeView.swift
//  pawpaw
//

import UIKit

/// The game's house button: a tap wiggles, a hold succeeds.
final class OnboardingHoldPracticeView: UIView {
    var onTap: (() -> Void)?
    var onHold: (() -> Void)?

    private let button = UIButton(type: .custom)
    private let check = UIImageView()
    private let hint: UILabel = {
        let label = UILabel()
        label.text = "Hold me"
        label.font = Theme.roundedFont(size: Theme.scaled(16), weight: .heavy)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Theme.gold
        label.textAlignment = .center
        // The button's hint already says this.
        label.isAccessibilityElement = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let side = max(Theme.minimumTapSize, Theme.scaled(76))
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "house.fill")
        config.baseForegroundColor = Theme.text
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: side * 0.38, weight: .bold)
        button.configuration = config
        button.accessibilityLabel = "Home"
        button.accessibilityHint = "Press and hold to practise leaving a game"
        button.accessibilityIdentifier = "onboardingHousePractice"
        button.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Press and hold") { [weak self] _ in
                self?.completeHold()
                return true
            }
        ]
        button.addHoldToConfirm(self, action: #selector(held(_:)))
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        // Palette, so the tick is solid rather than a cutout.
        let checkConfig = UIImage.SymbolConfiguration(pointSize: side * 0.3, weight: .black)
            .applying(UIImage.SymbolConfiguration(paletteColors: [Theme.background, Theme.gold]))
        check.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: checkConfig)
        check.alpha = 0
        check.isAccessibilityElement = false

        for part in [button, check, hint] as [UIView] {
            part.translatesAutoresizingMaskIntoConstraints = false
            addSubview(part)
        }
        // Centers the button and label together.
        let group = UILayoutGuide()
        addLayoutGuide(group)
        NSLayoutConstraint.activate([
            group.topAnchor.constraint(equalTo: button.topAnchor),
            group.bottomAnchor.constraint(equalTo: hint.bottomAnchor),
            group.centerYAnchor.constraint(equalTo: centerYAnchor),
            group.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            hint.topAnchor.constraint(equalTo: button.bottomAnchor, constant: Theme.scaled(8)),
            hint.centerXAnchor.constraint(equalTo: centerXAnchor),

            button.widthAnchor.constraint(equalToConstant: side),
            button.heightAnchor.constraint(equalToConstant: side),
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            // On the corner, outside the round hold ring.
            check.centerXAnchor.constraint(equalTo: button.trailingAnchor),
            check.centerYAnchor.constraint(equalTo: button.topAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Layer animations are dropped when the view leaves the window.
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, hint.alpha > 0 { startHintPulse() }
    }

    func reset() {
        check.layer.removeAllAnimations()
        check.alpha = 0
        check.transform = .identity
        button.configuration?.baseForegroundColor = Theme.text
        hint.alpha = 1
        startHintPulse()
    }

    private func startHintPulse() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1
        pulse.toValue = 1.12
        pulse.duration = 0.7
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        hint.layer.add(pulse, forKey: "pulse")
    }

    @objc private func tapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if !UIAccessibility.isReduceMotionEnabled {
            let wiggle = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            wiggle.values = [0, -0.18, 0.18, -0.1, 0.1, 0]
            wiggle.duration = 0.35
            button.layer.add(wiggle, forKey: "wiggle")
        }
        onTap?()
    }

    @objc private func held(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        completeHold()
    }

    private func completeHold() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        button.configuration?.baseForegroundColor = Theme.gold
        check.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
        UIView.animate(
            withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.8, options: []
        ) {
            self.check.alpha = 1
            self.check.transform = .identity
            self.hint.alpha = 0
        } completion: { _ in
            self.hint.layer.removeAnimation(forKey: "pulse")
        }
        onHold?()
    }
}
