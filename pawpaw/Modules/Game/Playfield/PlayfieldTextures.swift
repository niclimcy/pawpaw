//
//  PlayfieldTextures.swift
//  pawpaw
//

import SpriteKit
import UIKit

/// Artwork for the playfield, rendered once and cached. SpriteKit has no layer shadows,
/// so shadows and glows are drawn into each texture.
enum PlayfieldTextures {
    /// A critter's texture, with padding for its shadow.
    struct Critter {
        let texture: SKTexture
        /// On-screen size of the whole texture, padding included.
        let size: CGSize
        /// Side of the artwork itself, used for hit testing.
        let side: CGFloat
    }

    enum CritterStyle {
        case standard
        case caught
    }

    private struct Shadow {
        let color: UIColor
        let radius: CGFloat
        let offset: CGSize
    }

    private struct CritterKey: Hashable {
        let kind: TargetKind
        let variant: CritterVariant
        let style: CritterStyle
        let size: CGFloat
    }

    private static var critters: [CritterKey: Critter] = [:]
    private static var tintedArtwork: [CritterKey: UIImage] = [:]
    private static var textures: [String: SKTexture] = [:]

    // MARK: Critters

    /// `size` is before the variant's scale.
    static func critter(
        _ kind: TargetKind,
        variant: CritterVariant,
        size: CGFloat,
        style: CritterStyle = .standard
    ) -> Critter? {
        let key = CritterKey(kind: kind, variant: variant, style: style, size: size)
        if let cached = critters[key] { return cached }
        guard let artwork = artwork(for: kind, variant: variant, size: size) else { return nil }

        let side = size * variant.scale
        let shadow = critterShadow(kind: kind, variant: variant, style: style)
        let image = renderWithShadow(shadow, contentSize: CGSize(width: side, height: side)) {
            rect in
            artwork.draw(in: rect)
        }
        let critter = Critter(texture: SKTexture(image: image), size: image.size, side: side)
        critters[key] = critter
        return critter
    }

    private static func critterShadow(
        kind: TargetKind, variant: CritterVariant, style: CritterStyle
    )
        -> Shadow
    {
        if style == .caught {
            return Shadow(color: Theme.gold, radius: 18, offset: .zero)
        }
        if kind.movementStyle.surfaces {
            return Shadow(
                color: UIColor(red: 0, green: 0.05, blue: 0.15, alpha: 0.5), radius: 10,
                offset: .zero)
        }
        if kind.glows {
            // A light red glow reads by brightness to cats, who see pure red as dull.
            return Shadow(
                color: UIColor(red: 1, green: 0.45, blue: 0.42, alpha: 1),
                radius: 22 * variant.scale,
                offset: .zero)
        }
        return Shadow(
            color: UIColor.black.withAlphaComponent(0.6), radius: 6,
            offset: CGSize(width: 0, height: 4))
    }

    /// The critter's artwork with the variant's colour washed over it.
    /// The laser keeps its red dot; only its size and glow change.
    private static func artwork(for kind: TargetKind, variant: CritterVariant, size: CGFloat)
        -> UIImage?
    {
        guard let artwork = UIImage(named: kind.imageName) else { return nil }
        guard let tint = variant.tint, !kind.glows else { return artwork }
        let key = CritterKey(kind: kind, variant: variant, style: .standard, size: size)
        if let cached = tintedArtwork[key] { return cached }

        // Rendered at the shown size so the vector art stays sharp.
        let side = size * variant.scale
        let rect = CGRect(x: 0, y: 0, width: side, height: side)
        let image = UIGraphicsImageRenderer(size: rect.size).image { _ in
            artwork.draw(in: rect)
            UIColor(red: tint.red, green: tint.green, blue: tint.blue, alpha: tint.amount).setFill()
            // Source-atop only colours the artwork's own pixels.
            UIRectFillUsingBlendMode(rect, .sourceAtop)
        }
        tintedArtwork[key] = image
        return image
    }

    // MARK: Hiding spots

    static func hidingSpot(for theme: PlayfieldTheme, side: CGFloat) -> SKTexture {
        let shadow = Shadow(
            color: UIColor.black.withAlphaComponent(0.55), radius: 10,
            offset: CGSize(width: 0, height: 6)
        )
        return cached("spot.\(theme.rawValue).\(side)") {
            texture(side: side, shadow: shadow) {
                HidingSpotArtwork.draw(theme, in: $0.insetBy(dx: 6, dy: 6))
            }
        }
    }

    // MARK: Effects

    static let star = texture(side: 24, shadow: nil) { rect in
        let path = UIBezierPath()
        for i in 0..<8 {
            let radius = i % 2 == 0 ? rect.width / 2 : rect.width / 6
            let angle = CGFloat(i) * .pi / 4 - .pi / 2
            let point = CGPoint(
                x: rect.midX + cos(angle) * radius, y: rect.midY + sin(angle) * radius)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.close()
        UIColor.white.setFill()
        path.fill()
    }

    static let dot = texture(side: 12, shadow: nil) { rect in
        UIColor.white.setFill()
        UIBezierPath(ovalIn: rect).fill()
    }

    /// The gold glow behind a catch.
    static let flash = texture(
        side: 160, shadow: Shadow(color: Theme.gold, radius: 30, offset: .zero)
    ) { rect in
        Theme.gold.withAlphaComponent(0.55).setFill()
        UIBezierPath(ovalIn: rect).fill()
    }

    /// A white ring with a soft glow, tinted by the sprite's colour.
    static func ring(radius: CGFloat, lineWidth: CGFloat) -> SKTexture {
        cached("ring.\(radius).\(lineWidth)") {
            texture(
                side: radius * 2 + lineWidth,
                shadow: Shadow(color: .white, radius: 6, offset: .zero)
            ) { rect in
                let circle = UIBezierPath(
                    ovalIn: rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2))
                circle.lineWidth = lineWidth
                UIColor.white.setStroke()
                circle.stroke()
            }
        }
    }

    /// "+points" in the rounded game font, which `SKLabelNode` can't use reliably.
    static func points(_ points: Int) -> SKTexture {
        cached("points.\(points)") {
            let text = "+\(points)" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: Theme.roundedFont(size: 34), .foregroundColor: Theme.gold,
            ]
            let size = text.size(withAttributes: attributes)
            let shadow = Shadow(
                color: UIColor.black.withAlphaComponent(0.9), radius: 3,
                offset: CGSize(width: 0, height: 2)
            )
            let image = renderWithShadow(
                shadow, contentSize: CGSize(width: ceil(size.width), height: ceil(size.height))
            ) { rect in
                text.draw(in: rect, withAttributes: attributes)
            }
            return SKTexture(image: image)
        }
    }

    // MARK: Helpers

    private static func cached(_ key: String, make: () -> SKTexture) -> SKTexture {
        if let texture = textures[key] { return texture }
        let texture = make()
        textures[key] = texture
        return texture
    }

    private static func texture(side: CGFloat, shadow: Shadow?, content: (CGRect) -> Void)
        -> SKTexture
    {
        let none = Shadow(color: .clear, radius: 0, offset: .zero)
        return SKTexture(
            image: renderWithShadow(
                shadow ?? none, contentSize: CGSize(width: side, height: side), content: content))
    }

    /// Draws `content` centred in a canvas padded to fit its shadow on every side, so the
    /// texture's centre stays the artwork's centre.
    private static func renderWithShadow(
        _ shadow: Shadow, contentSize: CGSize, content: (CGRect) -> Void
    ) -> UIImage {
        let padding = ceil(
            shadow.radius * 2 + max(abs(shadow.offset.width), abs(shadow.offset.height)))
        let canvas = CGSize(
            width: contentSize.width + padding * 2, height: contentSize.height + padding * 2)
        return UIGraphicsImageRenderer(size: canvas).image { context in
            context.cgContext.setShadow(
                offset: shadow.offset, blur: shadow.radius * 2, color: shadow.color.cgColor)
            context.cgContext.beginTransparencyLayer(auxiliaryInfo: nil)
            content(CGRect(origin: CGPoint(x: padding, y: padding), size: contentSize))
            context.cgContext.endTransparencyLayer()
        }
    }
}
