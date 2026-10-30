//
//  GameViewController+ExitTip.swift
//  pawpaw
//

import UIKit

extension GameViewController {
    func installExitTip(in overlay: UIView) {
        guard let homeButton = hudHomeButton else { return }

        let label = UILabel()
        let font = Theme.roundedFont(size: Theme.scaled(16), weight: .bold)
        let text = NSMutableAttributedString(string: "Owners: press and hold ", attributes: [.font: font])
        let symbol = UIImage.SymbolConfiguration(font: font)
        if let house = UIImage(systemName: "house.fill", withConfiguration: symbol) {
            let tinted = house.withTintColor(Theme.text, renderingMode: .alwaysOriginal)
            text.append(NSAttributedString(attachment: NSTextAttachment(image: tinted)))
        }
        text.append(NSAttributedString(string: " to leave", attributes: [.font: font]))
        label.attributedText = text
        label.textColor = Theme.text
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        let bubble = UIView()
        bubble.backgroundColor = Theme.panel
        bubble.layer.cornerRadius = 16
        bubble.layer.borderWidth = 2
        bubble.layer.borderColor = Theme.accent.cgColor

        let arrow = TipArrowView()

        for subview in [label, bubble, arrow] {
            subview.translatesAutoresizingMaskIntoConstraints = false
        }
        bubble.addSubview(label)
        overlay.addSubview(bubble)
        overlay.addSubview(arrow)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -14),

            arrow.topAnchor.constraint(equalTo: homeButton.bottomAnchor, constant: 2),
            arrow.centerXAnchor.constraint(equalTo: homeButton.centerXAnchor),
            arrow.widthAnchor.constraint(equalToConstant: 18),
            arrow.heightAnchor.constraint(equalToConstant: 10),

            bubble.topAnchor.constraint(equalTo: arrow.bottomAnchor),
            bubble.leadingAnchor.constraint(equalTo: homeButton.leadingAnchor),
            bubble.trailingAnchor.constraint(
                lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            )
        ])
    }
}

private final class TipArrowView: UIView {
    private let shape = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        shape.fillColor = Theme.accent.cgColor
        layer.addSublayer(shape)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.midX, y: 0))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
        path.addLine(to: CGPoint(x: 0, y: bounds.maxY))
        path.close()
        shape.frame = bounds
        shape.path = path.cgPath
    }
}
