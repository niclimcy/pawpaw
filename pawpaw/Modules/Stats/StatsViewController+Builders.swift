//
//  StatsViewController+Builders.swift
//  pawpaw
//

import UIKit

extension StatsViewController {
    /// Quiet section heading so the numbers, not the captions, carry the page.
    static func makeSectionHeader(_ text: String) -> UILabel {
        let label = Theme.makeLabel(size: 14, weight: .bold)
        label.text = text
        label.textColor = Theme.sectionText
        label.accessibilityTraits = .header
        return label
    }

    static func makeTileLabel(size: CGFloat, weight: UIFont.Weight) -> UILabel {
        let label = Theme.makeLabel(size: size, weight: weight)
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        return label
    }

    static func makeDivider() -> UIView {
        let line = UIView()
        line.backgroundColor = Theme.divider
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
        let captionLabel = makeTileLabel(size: 13, weight: .semibold)
        captionLabel.text = caption
        captionLabel.textColor = Theme.captionText
        // Words wrap; only the numbers above shrink to fit.
        captionLabel.numberOfLines = 0
        captionLabel.adjustsFontSizeToFitWidth = false

        let tile = UIStackView(arrangedSubviews: [value, captionLabel])
        tile.axis = .vertical
        tile.alignment = .center
        tile.spacing = 4
        tile.isLayoutMarginsRelativeArrangement = true
        tile.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        tile.backgroundColor = Theme.tileFill
        tile.layer.cornerRadius = 16
        tile.isAccessibilityElement = true
        return tile
    }

    /// Two even rows of five.
    static var crittersPerRow: Int { 5 }

    static func makeCrittersStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8
        return stack
    }

    static func makeMetricTile(_ metric: StatsViewModel.Metric) -> UIView {
        let tile = makeTile(value: makeValueLabel(metric.value), caption: metric.caption)
        tile.accessibilityLabel = metric.accessibilityLabel
        return tile
    }

    static func makeValueLabel(_ text: String) -> UILabel {
        let label = makeTileLabel(size: 24, weight: .heavy)
        label.text = text
        return label
    }

    /// Critter artwork, or a dash when there is nothing to show yet.
    static func makeFavoriteValue(imageName: String?) -> UIView {
        guard let imageName, let image = UIImage(named: imageName) else {
            return makeValueLabel("–")
        }
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let side: CGFloat = 28
        imageView.widthAnchor.constraint(equalToConstant: side).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: side).isActive = true
        return imageView
    }

    /// A single accessibility element; the caller sets its label and large content title.
    static func makeCritterTile(imageName: String, catches: String, isEmpty: Bool) -> UIView {
        let imageView = UIImageView(image: UIImage(named: imageName))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let side: CGFloat = 30
        imageView.widthAnchor.constraint(equalToConstant: side).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: side).isActive = true
        imageView.isAccessibilityElement = false

        let countLabel = makeTileLabel(size: 16, weight: .bold)
        countLabel.text = catches

        let tile = UIStackView(arrangedSubviews: [imageView, countLabel])
        tile.axis = .vertical
        tile.alignment = .center
        tile.spacing = 4
        tile.isLayoutMarginsRelativeArrangement = true
        tile.layoutMargins = UIEdgeInsets(top: 6, left: 2, bottom: 6, right: 2)
        tile.backgroundColor = Theme.tileFill
        tile.layer.cornerRadius = 14
        tile.isAccessibilityElement = true
        tile.showsLargeContentViewer = true
        tile.largeContentImage = imageView.image
        tile.scalesLargeContentImage = true
        // Dim critters that haven't been caught yet so the ones that have stand out.
        imageView.alpha = isEmpty ? 0.35 : 1
        countLabel.alpha = isEmpty ? 0.5 : 1
        return tile
    }

    /// A single accessibility element; the caller sets its label and large content title.
    static func makeBar(label: String, rounds: Int, maxRounds: Int) -> UIView {
        let maxHeight: CGFloat = 56
        let bar = UIView()
        bar.backgroundColor = rounds > 0 ? Theme.accent : Theme.outline
        bar.layer.cornerRadius = 6
        bar.translatesAutoresizingMaskIntoConstraints = false
        let height = rounds > 0 ? max(maxHeight * CGFloat(rounds) / CGFloat(maxRounds), 10) : 4
        bar.heightAnchor.constraint(equalToConstant: height).isActive = true
        bar.widthAnchor.constraint(equalToConstant: 22).isActive = true

        let count = makeTileLabel(size: 14, weight: .bold)
        count.text = rounds > 0 ? "\(rounds)" : ""
        let name = makeTileLabel(size: 13, weight: .semibold)
        name.text = label
        name.textColor = Theme.captionText

        let column = UIStackView(arrangedSubviews: [count, bar, name])
        column.axis = .vertical
        column.alignment = .center
        column.spacing = 6
        column.isAccessibilityElement = true
        column.showsLargeContentViewer = true
        return column
    }
}
