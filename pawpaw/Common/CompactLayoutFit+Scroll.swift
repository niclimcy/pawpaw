//
//  CompactLayoutFit+Scroll.swift
//  pawpaw
//

import UIKit

extension CompactLayoutFit {
    /// For screens built with `embedCentered(_:footer:...)`; call from `viewDidLayoutSubviews`.
    /// Measures the scroll view's overflow against its host's safe area and returns `true` when
    /// `isCompact` changed, so the screen should apply its metrics.
    mutating func update(scroll: UIScrollView) -> Bool {
        guard let host = scroll.superview else { return false }
        let overflow =
            scroll.contentLayoutGuide.layoutFrame.height
            - scroll.frameLayoutGuide.layoutFrame.height
        let room = host.safeAreaLayoutGuide.layoutFrame.height
        return update(needed: room + overflow, room: room)
    }
}
