//
//  StatsViewController+Builders.swift
//  pawpaw
//

import UIKit

extension StatsViewController {
    static func makeLabel(size: CGFloat, weight: UIFont.Weight = .heavy) -> UILabel {
        let label = UILabel()
        label.font = Theme.roundedFont(size: size, weight: weight)
        label.textColor = Theme.text
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    static func makeRow() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .bottom
        stack.distribution = .fillEqually
        stack.spacing = 8
        return stack
    }

    static func makeColumn(top: String, topSize: CGFloat, bottom: String) -> UIView {
        let topLabel = makeLabel(size: topSize)
        topLabel.text = top
        let bottomLabel = makeLabel(size: 18, weight: .bold)
        bottomLabel.text = bottom
        let column = UIStackView(arrangedSubviews: [topLabel, bottomLabel])
        column.axis = .vertical
        column.alignment = .center
        column.spacing = 2
        return column
    }

    /// A vertical bar whose height is proportional to the rounds played that day.
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
        return column
    }
}
