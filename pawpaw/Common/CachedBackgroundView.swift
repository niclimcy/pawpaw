//
//  CachedBackgroundView.swift
//  pawpaw
//

import UIKit

/// A drawn background rendered once per size into an image, which is reused after that. Grass alone is
/// thousands of strokes on a large iPad, so it isn't redrawn on the main thread at every rotation or
/// screen change.
class CachedBackgroundView: UIView {
    /// Shared by every background, so going back to a screen or a size reuses the earlier drawing.
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        // A few full-screen images: the current backgrounds in both orientations.
        cache.countLimit = 8
        return cache
    }()

    private var renderedSize: CGSize = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = true
        isUserInteractionEnabled = false
        layer.contentsGravity = .resize
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Identifies what this view draws, apart from its size.
    var drawingKey: String {
        String(describing: type(of: self))
    }

    /// Draws the background into `ctx` for `size`. Subclasses override this.
    func drawBackground(in ctx: CGContext, size: CGSize) {}

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = bounds.size
        guard size.width > 0, size.height > 0, size != renderedSize else { return }
        renderedSize = size
        let key = "\(drawingKey)-\(Int(size.width))x\(Int(size.height))" as NSString
        if let cached = Self.cache.object(forKey: key) {
            show(cached)
            return
        }
        let image = UIGraphicsImageRenderer(size: size).image { context in
            drawBackground(in: context.cgContext, size: size)
        }
        Self.cache.setObject(image, forKey: key)
        show(image)
    }

    private func show(_ image: UIImage) {
        layer.contents = image.cgImage
        layer.contentsScale = image.scale
    }

    /// Darkens the corners so the middle of the field, where critters run, stands out.
    static func drawVignette(in ctx: CGContext, size: CGSize, darkness: CGFloat) {
        let colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(darkness).cgColor] as CFArray
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.45, 1]) else {
            return
        }
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = hypot(size.width, size.height) / 2
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
    }
}
