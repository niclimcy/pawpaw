//
//  PassthroughView.swift
//  pawpaw
//

import UIKit

/// Takes touches only on `interactiveView`; everywhere else they fall through to the views beneath.
final class PassthroughView: UIView {
    weak var interactiveView: UIView?

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let interactiveView, !interactiveView.isHidden else { return false }
        return interactiveView.point(inside: convert(point, to: interactiveView), with: event)
    }
}
