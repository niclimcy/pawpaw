//
//  StatsViewController+Builders.swift
//  pawpaw
//

import UIKit

extension StatsViewController {
    static var isPad: Bool { Theme.uiScale > 1 }

    /// The phone layout is tighter so the whole page fits on screen without scrolling.
    /// For fonts and artwork: the iPad value is scaled up by `Theme.uiScale`.
    static func adaptive(phone: CGFloat, pad: CGFloat) -> CGFloat {
        isPad ? Theme.scaled(pad) : phone
    }

    /// For padding and gaps: used as given on both idioms.
    static func spacing(phone: CGFloat, pad: CGFloat) -> CGFloat {
        isPad ? pad : phone
    }

    static func makeLabel(size: CGFloat, weight: UIFont.Weight = .heavy) -> UILabel {
        let label = UILabel()
        label.font = Theme.roundedFont(size: size, weight: weight)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Theme.text
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    /// Quiet section heading so the numbers, not the captions, carry the page.
    static func makeSectionHeader(_ text: String) -> UILabel {
        let label = makeLabel(size: Theme.scaled(14), weight: .bold)
        label.text = text
        label.textColor = Theme.text.withAlphaComponent(0.65)
        label.accessibilityTraits = .header
        return label
    }

    static func makeDivider() -> UIView {
        let line = UIView()
        line.backgroundColor = Theme.gold.withAlphaComponent(0.25)
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return line
    }

    static func makeRow(
        spacing: CGFloat = 8,
        alignment: UIStackView.Alignment = .bottom,
        distribution: UIStackView.Distribution = .fillEqually
    ) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = alignment
        stack.distribution = distribution
        stack.spacing = spacing
        return stack
    }

    /// Rounded inset tile used for the headline numbers and best scores.
    /// A single accessibility element; the caller sets its label.
    static func makeTile(value: UIView, caption: String) -> UIView {
        let captionLabel = makeLabel(size: Theme.scaled(13), weight: .semibold)
        captionLabel.text = caption
        captionLabel.textColor = Theme.text.withAlphaComponent(0.7)

        let tile = UIStackView(arrangedSubviews: [value, captionLabel])
        tile.axis = .vertical
        tile.alignment = .center
        tile.spacing = 4
        tile.isLayoutMarginsRelativeArrangement = true
        tile.layoutMargins = UIEdgeInsets(top: spacing(phone: 8, pad: 12), left: 8, bottom: spacing(phone: 8, pad: 12), right: 8)
        tile.backgroundColor = Theme.background.withAlphaComponent(0.45)
        tile.layer.cornerRadius = 16
        tile.isAccessibilityElement = true
        return tile
    }

    /// Five per row on phones.
    static var crittersPerRow: Int { isPad ? 4 : 5 }

    /// Rows of critter tiles, each centered so a short last row doesn't hug the left edge.
    static func makeCrittersStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = isPad ? .center : .fill
        stack.spacing = 8
        return stack
    }

    static func makeMetricTile(_ metric: StatsViewModel.Metric) -> UIView {
        let tile = makeTile(value: makeValueLabel(metric.value), caption: metric.caption)
        tile.accessibilityLabel = metric.accessibilityLabel
        return tile
    }

    static func makeValueLabel(_ text: String) -> UILabel {
        let label = makeLabel(size: adaptive(phone: 24, pad: 28), weight: .heavy)
        label.text = text
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        return label
    }

    /// Critter artwork, or a dash when there is nothing to show yet.
    static func makeFavoriteValue(imageName: String?) -> UIView {
        guard let imageName, let image = UIImage(named: imageName) else { return makeValueLabel("–") }
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let side = adaptive(phone: 28, pad: 34)
        imageView.widthAnchor.constraint(equalToConstant: side).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: side).isActive = true
        return imageView
    }

    /// A single accessibility element; the caller sets its label.
    static func makeCritterTile(imageName: String, catches: String, isEmpty: Bool) -> UIView {
        let imageView = UIImageView(image: UIImage(named: imageName))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let side = adaptive(phone: 30, pad: 40)
        imageView.widthAnchor.constraint(equalToConstant: side).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: side).isActive = true
        imageView.isAccessibilityElement = false

        let countLabel = makeLabel(size: adaptive(phone: 16, pad: 18), weight: .bold)
        countLabel.text = catches

        let tile = UIStackView(arrangedSubviews: [imageView, countLabel])
        tile.axis = .vertical
        tile.alignment = .center
        tile.spacing = 4
        tile.isLayoutMarginsRelativeArrangement = true
        tile.layoutMargins = UIEdgeInsets(top: spacing(phone: 6, pad: 10), left: 2, bottom: spacing(phone: 6, pad: 8), right: 2)
        tile.backgroundColor = Theme.background.withAlphaComponent(0.45)
        tile.layer.cornerRadius = 14
        tile.isAccessibilityElement = true
        // Dim critters that haven't been caught yet so the ones that have stand out.
        imageView.alpha = isEmpty ? 0.35 : 1
        countLabel.alpha = isEmpty ? 0.5 : 1
        // Phone rows split the width evenly; iPad uses fixed tiles so a short last row stays centered.
        if isPad { tile.widthAnchor.constraint(equalToConstant: Theme.scaled(64)).isActive = true }
        return tile
    }

    /// A single accessibility element; the caller sets its label.
    static func makeBar(label: String, rounds: Int, maxRounds: Int) -> UIView {
        let maxHeight = adaptive(phone: 56, pad: 80)
        let bar = UIView()
        bar.backgroundColor = rounds > 0 ? Theme.accent : Theme.text.withAlphaComponent(0.2)
        bar.layer.cornerRadius = 6
        bar.translatesAutoresizingMaskIntoConstraints = false
        let height = rounds > 0 ? max(maxHeight * CGFloat(rounds) / CGFloat(maxRounds), 10) : 4
        bar.heightAnchor.constraint(equalToConstant: height).isActive = true
        bar.widthAnchor.constraint(equalToConstant: Theme.scaled(22)).isActive = true

        let count = makeLabel(size: Theme.scaled(14), weight: .bold)
        count.text = rounds > 0 ? "\(rounds)" : ""
        let name = makeLabel(size: Theme.scaled(13), weight: .semibold)
        name.text = label
        name.textColor = Theme.text.withAlphaComponent(0.7)

        let column = UIStackView(arrangedSubviews: [count, bar, name])
        column.axis = .vertical
        column.alignment = .center
        column.spacing = 6
        column.isAccessibilityElement = true
        return column
    }
}
