//
//  CatFacePicker.swift
//  pawpaw
//

import UIKit

/// A grid of cat headshots with one always selected.
final class CatFacePicker: UIView {
    var onSelect: ((CatFace) -> Void)?
    private(set) var selectedFace: CatFace = .orange
    private var buttons: [CatFace: UIButton] = [:]

    /// `maxSide` caps the button size and centers the rows; `nil` fills the width.
    init(perRow: Int = 3, maxSide: CGFloat? = nil) {
        super.init(frame: .zero)
        build(perRow: perRow, maxSide: maxSide)
        select(.orange)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func select(_ face: CatFace) {
        selectedFace = face
        for (candidate, button) in buttons {
            let isSelected = candidate == face
            button.layer.borderColor = (isSelected ? Theme.gold : UIColor.clear).cgColor
            button.backgroundColor = isSelected
                ? Theme.accent.withAlphaComponent(0.35)
                : Theme.background.withAlphaComponent(0.5)
            button.accessibilityTraits = isSelected ? [.button, .selected] : .button
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        for button in buttons.values {
            button.layer.cornerRadius = button.bounds.width * 0.18
        }
    }

    // MARK: Building
    private func build(perRow: Int, maxSide: CGFloat?) {
        let spacing: CGFloat = 10
        let faces = CatFace.allCases
        let rows = stride(from: 0, to: faces.count, by: perRow).map { start in
            let row = UIStackView(arrangedSubviews: faces[start..<min(start + perRow, faces.count)].map(makeButton))
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = spacing
            return row
        }
        let grid = UIStackView(arrangedSubviews: rows)
        grid.axis = .vertical
        grid.alignment = .center
        grid.spacing = spacing
        grid.translatesAutoresizingMaskIntoConstraints = false
        addSubview(grid)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: topAnchor),
            grid.bottomAnchor.constraint(equalTo: bottomAnchor),
            grid.leadingAnchor.constraint(equalTo: leadingAnchor),
            grid.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        for row in rows {
            // Below `.defaultHigh` so the picker never narrows the layout it sits in.
            let fill = row.widthAnchor.constraint(equalTo: grid.widthAnchor)
            fill.priority = .defaultHigh - 1
            fill.isActive = true
            if let maxSide {
                let count = CGFloat(perRow)
                row.widthAnchor.constraint(lessThanOrEqualToConstant: maxSide * count + spacing * (count - 1)).isActive = true
            }
        }
    }

    private func makeButton(_ face: CatFace) -> UIButton {
        let button = UIButton(type: .custom)
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor.clear.cgColor
        button.accessibilityLabel = face.title
        button.accessibilityIdentifier = "face_\(face.rawValue)"
        button.heightAnchor.constraint(equalTo: button.widthAnchor).isActive = true
        button.addAction(UIAction { [weak self] _ in
            self?.select(face)
            self?.onSelect?(face)
        }, for: .touchUpInside)

        let picture = UIImageView(image: UIImage(named: face.imageName))
        picture.contentMode = .scaleAspectFit
        picture.isUserInteractionEnabled = false
        // The SVG's own size mustn't push the button bigger than the row allows.
        picture.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        picture.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        picture.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(picture)
        NSLayoutConstraint.activate([
            picture.topAnchor.constraint(equalTo: button.topAnchor, constant: 6),
            picture.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -6),
            picture.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 6),
            picture.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -6)
        ])
        buttons[face] = button
        return button
    }
}
