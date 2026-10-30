//
//  CatFace+Image.swift
//  pawpaw
//

import UIKit

extension CatFace {
    /// Rendered as `.alwaysOriginal` so button configurations don't tint it.
    func image(side: CGFloat) -> UIImage? {
        guard let source = UIImage(named: imageName) else { return nil }
        let size = CGSize(width: side, height: side)
        let drawn = UIGraphicsImageRenderer(size: size).image { _ in
            source.draw(in: CGRect(origin: .zero, size: size))
        }
        return drawn.withRenderingMode(.alwaysOriginal)
    }
}
