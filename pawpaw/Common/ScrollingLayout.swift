//
//  ScrollingLayout.swift
//  pawpaw
//

import UIKit

extension UIViewController {
    /// Centers `content` in a vertical scroll view that scrolls only when the content doesn't fit.
    /// `host` defaults to the controller's view.
    @discardableResult
    func embedCentered(_ content: UIView, maxWidth: CGFloat, margin: CGFloat = 24, in host: UIView? = nil) -> UIScrollView {
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
        let fillWidth = content.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -margin * 2)
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
            container.heightAnchor.constraint(greaterThanOrEqualTo: scroll.frameLayoutGuide.heightAnchor),

            content.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            content.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            content.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: margin),
            content.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -margin),
            // Required, so text that wants one long line can't push the content past the margins.
            content.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: margin),
            content.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -margin),
            content.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth),
            fillWidth
        ])
        return scroll
    }
}
