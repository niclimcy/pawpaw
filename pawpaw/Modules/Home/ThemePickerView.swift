//
//  ThemePickerView.swift
//  pawpaw
//

import UIKit

final class ThemePickerView: UIView {
    var onSelect: ((PlayfieldTheme) -> Void)?

    private var tiles: [ThemeTile] = []
    private let row = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        tiles = PlayfieldTheme.allCases.map { theme in
            let tile = ThemeTile(theme: theme)
            tile.addAction(UIAction { [weak self] _ in self?.tapped(theme) }, for: .touchUpInside)
            return tile
        }
        for tile in tiles {
            row.addArrangedSubview(tile)
        }
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.alignment = .top
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        accessibilityIdentifier = "themeControl"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func select(_ theme: PlayfieldTheme) {
        for tile in tiles {
            tile.isSelected = tile.theme == theme
        }
    }

    private func tapped(_ theme: PlayfieldTheme) {
        guard tiles.first(where: { $0.theme == theme })?.isSelected == false else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        select(theme)
        onSelect?(theme)
    }
}

final class ThemeTile: UIControl {
    let theme: PlayfieldTheme
    private let thumbnail: UIView
    private let nameLabel = UILabel()
    /// Shows selection without relying on the border colour alone.
    private let checkmark: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
            .applying(UIImage.SymbolConfiguration(paletteColors: [Theme.background, Theme.gold]))
        let view = UIImageView(
            image: UIImage(systemName: "checkmark.circle.fill", withConfiguration: config))
        view.isAccessibilityElement = false
        view.accessibilityIdentifier = "themeCheckmark"
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init(theme: PlayfieldTheme) {
        self.theme = theme
        let background: CachedBackgroundView =
            theme == .wood
            ? WoodCrateBackgroundView()
            : NatureBackgroundView(theme: theme)
        // Phone width, so the tile is a miniature of the full background.
        background.canvasWidth = 390
        thumbnail = background
        super.init(frame: .zero)

        thumbnail.layer.cornerRadius = 14
        thumbnail.clipsToBounds = true

        nameLabel.text = theme.title
        nameLabel.adjustsFontForContentSizeCategory = true
        // Wraps at large text sizes; shrinking is only the fallback.
        nameLabel.numberOfLines = 2
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.7
        nameLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [thumbnail, nameLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        addSubview(checkmark)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            thumbnail.heightAnchor.constraint(equalTo: thumbnail.widthAnchor, multiplier: 0.75),
            thumbnail.heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.minimumTapSize),
            checkmark.topAnchor.constraint(equalTo: thumbnail.topAnchor, constant: 6),
            checkmark.trailingAnchor.constraint(equalTo: thumbnail.trailingAnchor, constant: -6),
        ])

        isAccessibilityElement = true
        accessibilityLabel = theme.title
        accessibilityHint = "Background for the round"
        accessibilityIdentifier = "theme_\(theme.rawValue)"
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.7 : 1 }
    }

    private func updateAppearance() {
        thumbnail.layer.borderColor =
            (isSelected ? Theme.accent : Theme.outline).cgColor
        thumbnail.layer.borderWidth = isSelected ? 4 : 2
        checkmark.isHidden = !isSelected
        nameLabel.font = Theme.roundedFont(size: 14, weight: isSelected ? .heavy : .semibold)
        nameLabel.textColor = isSelected ? Theme.accent : Theme.bodyText
        accessibilityTraits = isSelected ? [.button, .selected] : .button
    }
}
