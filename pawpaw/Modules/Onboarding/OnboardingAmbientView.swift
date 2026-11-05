//
//  OnboardingAmbientView.swift
//  pawpaw
//

import UIKit

/// Faint critters drifting behind the card. Off with Reduce Motion.
final class OnboardingAmbientView: UIView {
    private static let kinds: [TargetKind] = [.mouse, .bug, .butterfly, .feather, .cricket]
    private static let maxCritters = 3
    private static let interval: TimeInterval = 2.5
    private var isRunning = false
    private var generation = 0
    private var kindIndex = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start() {
        guard !isRunning, !UIAccessibility.isReduceMotionEnabled else { return }
        isRunning = true
        tick(generation: generation)
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        generation += 1
        for critter in subviews { critter.removeFromSuperview() }
    }

    private func tick(generation: Int) {
        guard generation == self.generation else { return }
        if subviews.count < Self.maxCritters { launch() }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.interval) { [weak self] in
            self?.tick(generation: generation)
        }
    }

    private func launch() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let kind = Self.kinds[kindIndex % Self.kinds.count]
        kindIndex += 1
        let side = Theme.scaled(44)
        let critter = UIImageView(image: UIImage(named: kind.imageName))
        critter.contentMode = .scaleAspectFit
        critter.alpha = 0.22
        critter.frame.size = CGSize(width: side, height: side)

        let fromLeft = Bool.random()
        let startX = fromLeft ? -side : bounds.width + side
        let start = CGPoint(x: startX, y: CGFloat.random(in: 0...bounds.height))
        let end = CGPoint(
            x: bounds.width - startX, y: CGFloat.random(in: 0...bounds.height))
        // Artwork faces up; UIKit angles run clockwise.
        let heading = atan2(end.x - start.x, start.y - end.y)
        critter.center = start
        critter.transform = CGAffineTransform(rotationAngle: heading)
        addSubview(critter)

        UIView.animate(
            withDuration: .random(in: 9...14), delay: 0, options: [.curveLinear]
        ) {
            critter.center = end
        } completion: { _ in
            critter.removeFromSuperview()
        }
    }
}
