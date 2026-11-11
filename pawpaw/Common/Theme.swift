//
//  Theme.swift
//  pawpaw
//

import UIKit

enum Theme {
    static let background = UIColor(red: 0.16, green: 0.10, blue: 0.06, alpha: 1.0)
    static let panel = UIColor(red: 0.27, green: 0.17, blue: 0.10, alpha: 1.0)
    static let accent = UIColor(red: 1.0, green: 0.62, blue: 0.20, alpha: 1.0)
    static let gold = UIColor(red: 1.0, green: 0.84, blue: 0.30, alpha: 1.0)
    static let text = UIColor(red: 1.0, green: 0.94, blue: 0.80, alpha: 1.0)

    /// Text and icons on top of `accent`.
    static let onAccent = UIColor.white

    // Quieter shades of `text`, from strongest to faintest.
    static let bodyText = text.withAlphaComponent(0.85)
    static let buttonText = text.withAlphaComponent(0.8)
    static let detailText = text.withAlphaComponent(0.75)
    static let captionText = text.withAlphaComponent(0.7)
    static let sectionText = text.withAlphaComponent(0.65)
    static let outline = text.withAlphaComponent(0.2)
    static let cardOutline = text.withAlphaComponent(0.15)

    /// Dims the screen behind a modal card.
    static let scrim = UIColor.black.withAlphaComponent(0.55)
    /// Behind the options of a segmented control that sits on the playground.
    static let controlTrack = UIColor.black.withAlphaComponent(0.3)
    static let translucentPanel = panel.withAlphaComponent(0.85)
    static let cardBorder = gold.withAlphaComponent(0.6)
    static let divider = gold.withAlphaComponent(0.25)
    /// Inset tiles on a card.
    static let tileFill = background.withAlphaComponent(0.45)
    static let selectedChoiceFill = accent.withAlphaComponent(0.25)
    static let unselectedChoiceFill = background.withAlphaComponent(0.5)

    static let minimumTapSize: CGFloat = 44

    /// Long enough that a paw can't trigger owner-only actions by accident.
    static let holdDuration: TimeInterval = 1.5

    /// Cap on Dynamic Type growth so layouts don't break.
    static let maxTextScale: CGFloat = 1.5

    static func styleSegmented(
        _ control: UISegmentedControl,
        fontSize: CGFloat,
        selectedTint: UIColor = accent,
        selectedText: UIColor = onAccent
    ) {
        control.selectedSegmentTintColor = selectedTint
        control.backgroundColor = panel
        applySegmentedFonts(to: control, fontSize: fontSize, selectedText: selectedText)
        control.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumTapSize).isActive =
            true
    }

    /// Segmented controls don't follow Dynamic Type, so call again when the text size changes.
    static func applySegmentedFonts(
        to control: UISegmentedControl, fontSize: CGFloat, selectedText: UIColor = onAccent
    ) {
        let font = roundedFont(size: fontSize, weight: .bold)
        control.setTitleTextAttributes([.foregroundColor: text, .font: font], for: .normal)
        control.setTitleTextAttributes(
            [.foregroundColor: selectedText, .font: font], for: .selected)
    }

    /// Dynamic Type–scaled; set `adjustsFontForContentSizeCategory` on labels to follow changes live.
    static func roundedFont(size: CGFloat, weight: UIFont.Weight = .heavy) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        let rounded =
            base.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: size) }
            ?? base
        return UIFontMetrics.default.scaledFont(for: rounded, maximumPointSize: size * maxTextScale)
    }

    /// A centered, wrapping label in `text` colour.
    static func makeLabel(size: CGFloat, weight: UIFont.Weight = .heavy) -> UILabel {
        let label = UILabel()
        label.font = roundedFont(size: size, weight: weight)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = text
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    /// `text` with an SF Symbol before it (or after it, if `trailing`), sized and coloured to match the label it goes in.
    static func symbolText(
        _ symbolName: String,
        _ text: String,
        font: UIFont,
        color: UIColor,
        trailing: Bool = false
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text)
        let config = UIImage.SymbolConfiguration(font: font)
        if let symbol = UIImage(systemName: symbolName, withConfiguration: config) {
            let tinted = symbol.withTintColor(color, renderingMode: .alwaysOriginal)
            let icon = NSMutableAttributedString(attachment: NSTextAttachment(image: tinted))
            let gap = NSAttributedString(string: text.isEmpty ? "" : " ")
            if trailing {
                result.append(gap)
                result.append(icon)
            } else {
                icon.append(gap)
                result.insert(icon, at: 0)
            }
        }
        result.addAttributes(
            [.font: font, .foregroundColor: color],
            range: NSRange(location: 0, length: result.length)
        )
        return result
    }

    static func styleCard(_ card: UIView) {
        card.backgroundColor = panel
        card.layer.borderWidth = 3
        card.layer.borderColor = cardBorder.cgColor
        card.layer.cornerRadius = 28
    }

    static func filledButton(
        title: String,
        image: String? = nil,
        fontSize: CGFloat = 20,
        weight: UIFont.Weight = .bold,
        background: UIColor = accent,
        foreground: UIColor = onAccent,
        insets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(
            top: 14, leading: 36, bottom: 14, trailing: 36)
    ) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = image.flatMap { UIImage(systemName: $0) }
        config.imagePadding = 6
        config.baseBackgroundColor = background
        config.baseForegroundColor = foreground
        config.cornerStyle = .capsule
        config.contentInsets = insets
        config.titleTextAttributesTransformer = fontTransformer(size: fontSize, weight: weight)
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumTapSize).isActive = true
        return button
    }

    static func plainButton(
        title: String,
        image: String? = nil,
        fontSize: CGFloat = 16,
        foreground: UIColor = buttonText
    ) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = image.flatMap { UIImage(systemName: $0) }
        config.imagePadding = 6
        config.baseForegroundColor = foreground
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 12, leading: 16, bottom: 12, trailing: 16)
        config.titleTextAttributesTransformer = fontTransformer(size: fontSize, weight: .bold)
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumTapSize).isActive = true
        return button
    }

    static func fontTransformer(size: CGFloat, weight: UIFont.Weight)
        -> UIConfigurationTextAttributesTransformer
    {
        // Built on each update so the title follows text-size changes.
        UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = roundedFont(size: size, weight: weight)
            return outgoing
        }
    }
}

extension UILongPressGestureRecognizer {
    /// The action receives `.began` once `Theme.holdDuration` has elapsed.
    static func holdToConfirm(_ target: Any, _ action: Selector) -> UILongPressGestureRecognizer {
        let hold = UILongPressGestureRecognizer(target: target, action: action)
        hold.minimumPressDuration = Theme.holdDuration
        return hold
    }
}
