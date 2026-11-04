//
//  PlayfieldGeometry.swift
//  pawpaw
//

import CoreGraphics

/// Maps the planner's normalized (0...1, top-left origin) field to scene points (bottom-left origin).
/// The scene fills the screen so critters can run off any edge, but the field where they spawn,
/// stop and hide sits `topInset` below the top, clear of the HUD.
struct PlayfieldGeometry {
    static let targetSize: CGFloat = 126
    static let hidingSpotSize: CGFloat = 170

    var size: CGSize
    var topInset: CGFloat = 0

    /// The whole scene, including the strip under the HUD.
    var bounds: CGRect {
        CGRect(origin: .zero, size: size)
    }

    /// The part of the scene below the HUD.
    var field: CGRect {
        CGRect(x: 0, y: 0, width: size.width, height: max(size.height - topInset, 0))
    }

    func point(for normalized: CGPoint) -> CGPoint {
        let inset = Self.targetSize / 2 + 8
        let width = max(field.width - inset * 2, 0)
        let height = max(field.height - inset * 2, 0)
        return CGPoint(x: inset + normalized.x * width, y: field.maxY - inset - normalized.y * height)
    }

    /// Like `point(for:)`, but border points are pushed fully off-screen, past the HUD at the top.
    func offscreenPoint(for normalized: CGPoint) -> CGPoint {
        var result = point(for: normalized)
        let margin = Self.targetSize * 0.75
        if normalized.x <= 0 { result.x = -margin }
        if normalized.x >= 1 { result.x = size.width + margin }
        if normalized.y <= 0 { result.y = size.height + margin }
        if normalized.y >= 1 { result.y = -margin }
        return result
    }

    /// Picks the field edge nearest `point`, then runs past the screen edge on that side.
    func hideEdgePoint(from point: CGPoint) -> CGPoint {
        let margin = Self.targetSize * 0.75
        let gaps = [point.x, size.width - point.x, point.y, field.maxY - point.y]
        switch gaps.firstIndex(of: gaps.min() ?? 0) {
        case 0: return CGPoint(x: -margin, y: point.y)
        case 1: return CGPoint(x: size.width + margin, y: point.y)
        case 2: return CGPoint(x: point.x, y: -margin)
        default: return CGPoint(x: point.x, y: size.height + margin)
        }
    }

    func peekPoint(from point: CGPoint) -> CGPoint {
        let angle = CGFloat.random(in: 0..<(2 * .pi))
        let reach = Self.hidingSpotSize / 2
        return CGPoint(x: point.x + cos(angle) * reach, y: point.y + sin(angle) * reach)
    }

    /// A short peck forward along the last move.
    func nodPoint(from previous: CGPoint, to point: CGPoint) -> CGPoint {
        let dx = point.x - previous.x
        let dy = point.y - previous.y
        let length = max(hypot(dx, dy), 1)
        let reach: CGFloat = 10
        return CGPoint(x: point.x + dx / length * reach, y: point.y + dy / length * reach)
    }

    /// Stereo pan for a sound at `x`: -0.8 at the left edge to 0.8 at the right, never fully one-sided.
    func pan(atX x: CGFloat) -> Float {
        guard size.width > 0 else { return 0 }
        let normalized = min(max(x / size.width, 0), 1) * 2 - 1
        return Float(normalized) * 0.8
    }
}
