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

    /// `onAccent` for buttons filled with `Theme.accent`, where an accent ring wouldn't show.
    init(onAccent: Bool = false) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        for shape in [track, progress] {
            shape.fillColor = UIColor.clear.cgColor
            shape.lineWidth = 3
            shape.lineCap = .round
            layer.addSublayer(shape)
        }
        track.strokeColor =
            (onAccent ? Theme.onAccent.withAlphaComponent(0.25) : Theme.outline).cgColor
        progress.strokeColor = (onAccent ? Theme.onAccent : Theme.accent).cgColor
        progress.strokeEnd = 0
        alpha = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let rect = bounds.insetBy(dx: 1.5, dy: 1.5)
        let path =
            abs(rect.width - rect.height) < 1
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
        UIView.animate(
            withDuration: 0.15, animations: { self.alpha = 0 },
            completion: { _ in
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

        let ring = HoldProgressView(onAccent: configuration?.baseBackgroundColor == Theme.accent)
        ring.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ring)
        NSLayoutConstraint.activate([
            ring.topAnchor.constraint(equalTo: topAnchor),
            ring.bottomAnchor.constraint(equalTo: bottomAnchor),
            ring.leadingAnchor.constraint(equalTo: leadingAnchor),
            ring.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        addAction(
            UIAction { [weak ring] _ in ring?.start(duration: Theme.holdDuration) }, for: .touchDown
        )
        addAction(
            UIAction { [weak ring] _ in ring?.reset() },
            for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
        )
    }

    /// VoiceOver and Voice Control can't easily hold for `Theme.holdDuration`, so they get the
    /// confirmed action from the actions rotor or "Show actions" instead.
    func setHoldAccessibilityAction(_ name: String, handler: @escaping @MainActor () -> Void) {
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: name) { _ in
                handler()
                return true
            }
        ]
    }
}

extension UIViewController {
    private static let holdHintTag = 9_001

    /// Owner hint for a plain tap on a hold-to-confirm button. Sits above `anchor` when given,
    /// otherwise near the bottom of the safe area.
    func showHoldHint(_ message: String, above anchor: NSLayoutYAxisAnchor? = nil) {
        view.viewWithTag(Self.holdHintTag)?.removeFromSuperview()

        let hint = Theme.filledButton(
            title: message,
            fontSize: 16,
            background: Theme.panel,
            foreground: Theme.text,
            insets: NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18)
        )
        hint.configuration?.titleAlignment = .center
        hint.tag = Self.holdHintTag
        hint.isUserInteractionEnabled = false
        hint.alpha = 0
        hint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hint)
        let bottom =
            anchor.map { hint.bottomAnchor.constraint(equalTo: $0, constant: -12) }
            ?? hint.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        NSLayoutConstraint.activate([
            hint.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            bottom,
            hint.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            hint.trailingAnchor.constraint(
                lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
        ])
        UIAccessibility.post(notification: .announcement, argument: message)
        UIView.animate(
            withDuration: 0.2, animations: { hint.alpha = 1 },
            completion: { _ in
                UIView.animate(
                    withDuration: 0.4, delay: 2.0, options: [], animations: { hint.alpha = 0 },
                    completion: { _ in
                        hint.removeFromSuperview()
                    })
            })
    }
}
