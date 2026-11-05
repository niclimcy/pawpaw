//
//  ScrollingLayout.swift
//  pawpaw
//

import UIKit

extension UIViewController {
    /// Centers `content` in a vertical scroll view that scrolls only when the content doesn't fit.
    /// `host` defaults to the controller's view.
    @discardableResult
    func embedCentered(
        _ content: UIView, maxWidth: CGFloat, margin: CGFloat = 24, in host: UIView? = nil
    ) -> UIScrollView {
        let host = host ?? view!
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(scroll)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(container)

        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)

        // Lower priority so `maxWidth` wins.
        let fillWidth = content.widthAnchor.constraint(
            equalTo: container.widthAnchor, constant: -margin * 2)
        fillWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: host.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: host.safeAreaLayoutGuide.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: host.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: host.safeAreaLayoutGuide.trailingAnchor),

            container.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            container.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            container.heightAnchor.constraint(
                greaterThanOrEqualTo: scroll.frameLayoutGuide.heightAnchor),

            content.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            content.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            content.topAnchor.constraint(
                greaterThanOrEqualTo: container.topAnchor, constant: margin),
            content.bottomAnchor.constraint(
                lessThanOrEqualTo: container.bottomAnchor, constant: -margin),
            // Required, so text that wants one long line can't push the content past the margins.
            content.leadingAnchor.constraint(
                greaterThanOrEqualTo: container.leadingAnchor, constant: margin),
            content.trailingAnchor.constraint(
                lessThanOrEqualTo: container.trailingAnchor, constant: -margin),
            content.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth),
            fillWidth,
        ])
        return scroll
    }

    /// Like `embedCentered(_:maxWidth:margin:in:)`, but `footer` (the screen's main actions) never scrolls away.
    /// While everything fits, `content` and `footer` are centered together as one group. When it doesn't,
    /// the footer pins to the bottom of the safe area and only `content` scrolls in the space above it.
    /// The footer is as wide as `content`, so its multi-line labels wrap at the same width.
    @discardableResult
    func embedCentered(
        _ content: UIView,
        footer: UIView,
        maxWidth: CGFloat,
        margin: CGFloat = 24,
        verticalMargin: CGFloat? = nil,
        footerSpacing: CGFloat = 16,
        in host: UIView? = nil
    ) -> UIScrollView {
        let host = host ?? view!
        let area = host.safeAreaLayoutGuide
        let verticalMargin = verticalMargin ?? margin

        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(scroll)

        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        footer.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(footer)

        let contentGuide = scroll.contentLayoutGuide
        let frameGuide = scroll.frameLayoutGuide

        // Lower priority so `maxWidth` wins.
        let fillWidth = content.widthAnchor.constraint(
            equalTo: frameGuide.widthAnchor, constant: -margin * 2)
        fillWidth.priority = .defaultHigh

        // The scroll view is as tall as its content until that no longer fits; past that it scrolls.
        let hug = frameGuide.heightAnchor.constraint(equalTo: contentGuide.heightAnchor)
        hug.priority = scrollFitPriority

        // Content and footer stay together, centered in the space.
        let group = UILayoutGuide()
        host.addLayoutGuide(group)
        let center = group.centerYAnchor.constraint(equalTo: area.centerYAnchor)
        center.priority = .defaultLow

        NSLayoutConstraint.activate([
            group.topAnchor.constraint(equalTo: scroll.topAnchor),
            group.bottomAnchor.constraint(equalTo: footer.bottomAnchor),
            center,

            scroll.topAnchor.constraint(greaterThanOrEqualTo: area.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: area.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: area.trailingAnchor),
            hug,

            contentGuide.widthAnchor.constraint(equalTo: frameGuide.widthAnchor),
            content.topAnchor.constraint(equalTo: contentGuide.topAnchor, constant: verticalMargin),
            content.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),
            content.centerXAnchor.constraint(equalTo: contentGuide.centerXAnchor),
            // Required, so text that wants one long line can't push the content past the margins.
            content.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentGuide.leadingAnchor, constant: margin),
            content.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth),
            fillWidth,

            footer.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: footerSpacing),
            footer.bottomAnchor.constraint(
                lessThanOrEqualTo: area.bottomAnchor, constant: -verticalMargin),
            footer.centerXAnchor.constraint(equalTo: area.centerXAnchor),
            footer.widthAnchor.constraint(equalTo: content.widthAnchor),
        ])
        return scroll
    }
}

/// Just below the default compression resistance, so content that doesn't fit scrolls
/// rather than squashing labels and controls.
private let scrollFitPriority = UILayoutPriority(UILayoutPriority.defaultHigh.rawValue - 1)

/// Picks a tighter layout only when the regular one doesn't fit, e.g. on an iPhone SE.
/// Measuring rather than checking the screen size also covers Dynamic Type and iPad split view.
struct CompactLayoutFit {
    private(set) var isCompact = false
    /// The height the regular layout needed when it last didn't fit.
    private var regularNeeds: CGFloat = 0

    /// Back to the regular layout, e.g. after the text size changes; the next `update` measures again.
    mutating func reset() {
        isCompact = false
        regularNeeds = 0
    }

    /// Call after layout. `needed` is the height the current layout wants, `room` the height it has.
    /// Returns `true` when `isCompact` changed, so the caller should apply its metrics and lay out again.
    mutating func update(needed: CGFloat, room: CGFloat) -> Bool {
        guard room > 0 else { return false }
        if isCompact {
            guard room >= regularNeeds else { return false }
            isCompact = false
        } else {
            guard needed > room + 0.5 else { return false }
            regularNeeds = needed
            isCompact = true
        }
        return true
    }
}
