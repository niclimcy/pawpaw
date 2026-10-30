//
//  HoldToConfirm.swift
//  pawpaw
//

import UIKit

/// Outline that fills while a hold-to-confirm button is held.
final class HoldProgressView: UIView {
    private let track = CAShapeLayer()
    private let progress = CAShapeLayer()
    private var isHolding = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        for shape in [track, progress] {
            shape.fillColor = UIColor.clear.cgColor
            shape.lineWidth = 3
            shape.lineCap = .round
            layer.addSublayer(shape)
        }
        track.strokeColor = Theme.text.withAlphaComponent(0.2).cgColor
        progress.strokeColor = Theme.accent.cgColor
        progress.strokeEnd = 0
        alpha = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let rect = bounds.insetBy(dx: 1.5, dy: 1.5)
        let path = abs(rect.width - rect.height) < 1
            ? UIBezierPath(ovalIn: rect)
            : UIBezierPath(roundedRect: rect, cornerRadius: rect.height / 2)
        for shape in [track, progress] {
            shape.frame = bounds
            shape.path = path.cgPath
        }
    }

    func start(duration: TimeInterval) {
        isHolding = true
        progress.removeAllAnimations()
        alpha = 1
        let fill = CABasicAnimation(keyPath: "strokeEnd")
        fill.fromValue = 0
        fill.toValue = 1
        fill.duration = duration
        fill.fillMode = .forwards
        fill.isRemovedOnCompletion = false
        progress.add(fill, forKey: "fill")
    }

    func reset() {
        isHolding = false
        UIView.animate(withDuration: 0.15, animations: { self.alpha = 0 }, completion: { _ in
            // A new hold may have started during the fade.
            guard !self.isHolding else { return }
            self.progress.removeAllAnimations()
        })
    }
}

extension UIButton {
    /// The action receives `.began` once `Theme.holdDuration` has elapsed.
    func addHoldToConfirm(_ target: Any, action: Selector) {
        addGestureRecognizer(UILongPressGestureRecognizer.holdToConfirm(target, action))

        let ring = HoldProgressView()
        ring.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ring)
        NSLayoutConstraint.activate([
            ring.topAnchor.constraint(equalTo: topAnchor),
            ring.bottomAnchor.constraint(equalTo: bottomAnchor),
            ring.leadingAnchor.constraint(equalTo: leadingAnchor),
            ring.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        addAction(UIAction { [weak ring] _ in ring?.start(duration: Theme.holdDuration) }, for: .touchDown)
        addAction(
            UIAction { [weak ring] _ in ring?.reset() },
            for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
        )
    }
}
