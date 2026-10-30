//
//  GameAreaView+Variants.swift
//  pawpaw
//

import UIKit

extension GameAreaView {
    private static var variantImages: [String: UIImage] = [:]

    /// The critter's artwork with the variant's colour washed over it, rendered once per kind and variant.
    /// The laser keeps its red dot; only its size and glow change.
    func image(for kind: TargetKind, variant: CritterVariant) -> UIImage? {
        guard let artwork = UIImage(named: kind.imageName) else { return nil }
        guard let tint = variant.tint, !kind.glows else { return artwork }
        let key = "\(kind.rawValue).\(variant.rawValue)"
        if let cached = Self.variantImages[key] { return cached }

        // Rendered at the shown size so the vector art stays sharp.
        let side = targetSize * variant.scale
        let rect = CGRect(x: 0, y: 0, width: side, height: side)
        let image = UIGraphicsImageRenderer(size: rect.size).image { _ in
            artwork.draw(in: rect)
            UIColor(red: tint.red, green: tint.green, blue: tint.blue, alpha: tint.amount).setFill()
            // Source-atop only colours the artwork's own pixels.
            UIRectFillUsingBlendMode(rect, .sourceAtop)
        }
        Self.variantImages[key] = image
        return image
    }
}
