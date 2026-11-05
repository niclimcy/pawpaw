//
//  OnboardingCountdownView.swift
//  pawpaw
//

import UIKit

/// Loops device-flat, 3-2-1, paw. Static with Reduce Motion.
final class OnboardingCountdownView: UIView {
    private let device = UIImageView()
    private let number = UILabel()
    private let paw = UIImageView()
    private let stack = UIStackView()
    /// Invalidates pending loop steps on stop.
    private var generation = 0
    private var isRunning = false
    private let side = Theme.scaled(64)

    override init(frame: CGRect) {
        super.init(frame: frame)
        let symbol = UIImage.SymbolConfiguration(pointSize: side * 0.75, weight: .semibold)
        // Portrait symbols; the animation turns them to landscape.
        let deviceName = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        device.image = UIImage(systemName: deviceName, withConfiguration: symbol)
        device.tintColor = Theme.text
        paw.image = UIImage(systemName: "pawprint.fill", withConfiguration: symbol)
        paw.tintColor = Theme.gold
        number.textColor = Theme.accent
        number.textAlignment = .center
        number.adjustsFontSizeToFitWidth = true
        number.minimumScaleFactor = 0.5

        for part in [device, number, paw] as [UIView] {
            part.contentMode = .center
            part.widthAnchor.constraint(equalToConstant: side).isActive = true
            part.heightAnchor.constraint(equalToConstant: side).isActive = true
            stack.addArrangedSubview(part)
        }
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Theme.scaled(16)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
        ])

        isAccessibilityElement = true
        accessibilityLabel = "Lay the device flat. It counts 3, 2, 1, then your cat plays."
        accessibilityTraits = .image
        showStill()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        guard !UIAccessibility.isReduceMotionEnabled else {
            showStill()
            return
        }
        runLoop(generation: generation)
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        generation += 1
        for part in [device, number, paw] { part.layer.removeAllAnimations() }
        showStill()
    }

    private func showStill() {
        device.transform = .identity
        number.font = Theme.roundedFont(size: Theme.scaled(22), weight: .black)
        number.text = "3·2·1"
        number.alpha = 1
        number.transform = .identity
        paw.alpha = 1
        paw.transform = .identity
    }

    private func runLoop(generation: Int) {
        guard generation == self.generation else { return }
        number.font = Theme.roundedFont(size: Theme.scaled(44), weight: .black)
        number.text = nil
        paw.alpha = 0
        device.transform = .identity
        // Rotation only: scaling distorts the symbol and moving it breaks the row's alignment.
        UIView.animate(
            withDuration: 0.6, delay: 0.4, usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.4, options: []
        ) {
            self.device.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        } completion: { _ in
            self.count(3, generation: generation)
        }
    }

    private func count(_ value: Int, generation: Int) {
        guard generation == self.generation else { return }
        guard value > 0 else {
            pounce(generation: generation)
            return
        }
        number.text = "\(value)"
        number.alpha = 0
        number.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
            self.number.alpha = 1
            self.number.transform = .identity
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.count(value - 1, generation: generation)
        }
    }

    private func pounce(generation: Int) {
        number.text = nil
        paw.transform = CGAffineTransform(translationX: 0, y: -side * 0.5).scaledBy(x: 1.5, y: 1.5)
        UIView.animate(
            withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.45,
            initialSpringVelocity: 0.8, options: []
        ) {
            self.paw.alpha = 1
            self.paw.transform = .identity
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            guard let self, generation == self.generation else { return }
            UIView.animate(withDuration: 0.3) {
                self.paw.alpha = 0
                self.device.transform = .identity
            } completion: { _ in
                self.runLoop(generation: generation)
            }
        }
    }
}
