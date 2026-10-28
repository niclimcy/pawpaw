//
//  StatsViewController+Builders.swift
//  pawpaw
//

import UIKit

extension StatsViewController {
    static func makeLabel(size: CGFloat, weight: UIFont.Weight = .heavy) -> UILabel {
        let label = UILabel()
        label.font = Theme.roundedFont(size: size, weight: weight)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Theme.text
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    /// "Favorite catch:" followed by the critter's artwork, sized to the text.
    static func favoriteText(_ text: String, imageName: String?, font: UIFont) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: Theme.text
        ])
        guard let imageName, let image = UIImage(named: imageName) else { return result }
        let attachment = NSTextAttachment(image: image)
        let side = font.lineHeight * 1.6
        attachment.bounds = CGRect(x: 0, y: -side * 0.3, width: side, height: side)
        result.append(NSAttributedString(string: " "))
        result.append(NSAttributedString(attachment: attachment))
        return result
    }

    static func makeRow() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .bottom
        stack.distribution = .fillEqually
        stack.spacing = 8
        return stack
    }

    /// A critter's artwork over its catch count. VoiceOver reads the column as one element; set its label.
    static func makeColumn(imageName: String, size: CGFloat, bottom: String) -> UIView {
        let imageView = UIImageView(image: UIImage(named: imageName))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: size).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: size).isActive = true
        imageView.isAccessibilityElement = false

        let bottomLabel = makeLabel(size: 18, weight: .bold)
        bottomLabel.text = bottom
        let column = UIStackView(arrangedSubviews: [imageView, bottomLabel])
        column.axis = .vertical
        column.alignment = .center
        column.spacing = 2
        column.isAccessibilityElement = true
        return column
    }

    /// A vertical bar whose height is proportional to the rounds played that day.
    /// VoiceOver reads the bar as one element; set its label.
    static func makeBar(label: String, rounds: Int, maxRounds: Int) -> UIView {
        let maxHeight: CGFloat = 70
        let bar = UIView()
        bar.backgroundColor = rounds > 0 ? Theme.accent : Theme.text.withAlphaComponent(0.2)
        bar.layer.cornerRadius = 4
        bar.translatesAutoresizingMaskIntoConstraints = false
        let height = rounds > 0 ? max(maxHeight * CGFloat(rounds) / CGFloat(maxRounds), 8) : 4
        bar.heightAnchor.constraint(equalToConstant: height).isActive = true
        bar.widthAnchor.constraint(equalToConstant: 18).isActive = true

        let count = makeLabel(size: 14, weight: .bold)
        count.text = rounds > 0 ? "\(rounds)" : ""
        let name = makeLabel(size: 13, weight: .semibold)
        name.text = label

        let column = UIStackView(arrangedSubviews: [count, bar, name])
        column.axis = .vertical
        column.alignment = .center
        column.spacing = 4
        column.isAccessibilityElement = true
        return column
    }
}
