//
//  Theme.swift
//  pawpaw
//

import UIKit

enum Theme {
    /// Base colour of the dark wooden crate.
    static let background = UIColor(red: 0.16, green: 0.10, blue: 0.06, alpha: 1.0)
    /// Slightly lighter wood used for cards/panels.
    static let panel = UIColor(red: 0.27, green: 0.17, blue: 0.10, alpha: 1.0)
    static let accent = UIColor(red: 1.0, green: 0.62, blue: 0.20, alpha: 1.0)
    static let gold = UIColor(red: 1.0, green: 0.84, blue: 0.30, alpha: 1.0)
    static let text = UIColor(red: 1.0, green: 0.94, blue: 0.80, alpha: 1.0)

    /// Apple's minimum comfortable touch target.
    static let minimumTapSize: CGFloat = 44

    /// How long an owner holds a button to leave a round, open or reset stats, or delete a cat.
    /// Long enough that a paw can't do it by accident.
    static let holdDuration: TimeInterval = 1.5

    /// `holdDuration` as owners read it, such as "1.5 seconds".
    static var holdDurationText: String {
        "\(String(format: "%g", holdDuration)) seconds"
    }

    /// Text grows with the owner's Dynamic Type setting, up to this multiple of its design size,
    /// so the largest accessibility sizes stay readable without breaking the layouts.
    static let maxTextScale: CGFloat = 1.5

    /// Menus are laid out for a phone and scaled up on iPad.
    static var uiScale: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 1.4 : 1
    }

    static func scaled(_ value: CGFloat) -> CGFloat {
        value * uiScale
    }

    /// Dark-wood styling shared by the Home pickers.
    static func styleSegmented(_ control: UISegmentedControl, fontSize: CGFloat) {
        control.selectedSegmentTintColor = accent
        control.backgroundColor = panel
        applySegmentedFonts(to: control, fontSize: fontSize)
        control.heightAnchor.constraint(greaterThanOrEqualToConstant: max(minimumTapSize, scaled(36))).isActive = true
    }

    /// Segmented controls don't follow Dynamic Type on their own, so call this again when the text size changes.
    static func applySegmentedFonts(to control: UISegmentedControl, fontSize: CGFloat) {
        let font = roundedFont(size: scaled(fontSize), weight: .bold)
        control.setTitleTextAttributes([.foregroundColor: text, .font: font], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: font], for: .selected)
    }

    /// The rounded system font at `size`, scaled for the owner's Dynamic Type setting.
    /// Labels that use it should set `adjustsFontForContentSizeCategory` to follow changes live.
    static func roundedFont(size: CGFloat, weight: UIFont.Weight = .heavy) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        let rounded = base.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: size) } ?? base
        return UIFontMetrics.default.scaledFont(for: rounded, maximumPointSize: size * maxTextScale)
    }

    /// The wood panel with a gold border used by every card.
    static func styleCard(_ card: UIView) {
        card.backgroundColor = panel
        card.layer.borderWidth = 3
        card.layer.borderColor = gold.withAlphaComponent(0.6).cgColor
        card.layer.cornerRadius = 28
    }

    /// A filled capsule button, such as Play Again, Save or Back.
    static func filledButton(
        title: String,
        image: String? = nil,
        fontSize: CGFloat = 20,
        weight: UIFont.Weight = .bold,
        background: UIColor = accent,
        foreground: UIColor = .white,
        insets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 14, leading: 36, bottom: 14, trailing: 36)
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

    /// A borderless text button, such as Cancel or the hold-to buttons.
    static func plainButton(
        title: String,
        image: String? = nil,
        fontSize: CGFloat = 16,
        foreground: UIColor = text.withAlphaComponent(0.8)
    ) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = image.flatMap { UIImage(systemName: $0) }
        config.imagePadding = 6
        config.baseForegroundColor = foreground
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        config.titleTextAttributesTransformer = fontTransformer(size: fontSize, weight: .bold)
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumTapSize).isActive = true
        return button
    }

    /// Gives a button configuration's title the rounded font, scaled for iPad and Dynamic Type.
    static func fontTransformer(size: CGFloat, weight: UIFont.Weight) -> UIConfigurationTextAttributesTransformer {
        UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = roundedFont(size: scaled(size), weight: weight)
            return outgoing
        }
    }
}

extension UILongPressGestureRecognizer {
    /// A press-and-hold that fires only after `Theme.holdDuration`, so a paw can't trigger it by accident.
    /// The action sees `.began` once the full hold has passed.
    static func holdToConfirm(_ target: Any, _ action: Selector) -> UILongPressGestureRecognizer {
        let hold = UILongPressGestureRecognizer(target: target, action: action)
        hold.minimumPressDuration = Theme.holdDuration
        return hold
    }
}
