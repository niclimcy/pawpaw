//
//  LureCover.swift
//  pawpaw
//

import CoreGraphics

/// The results card as cover for the critter that roams it between rounds.
/// Normalized (0...1, top-left origin) like the planner's field; the card may reach past it.
struct LureCover: Equatable {
    /// A stop hidden just inside the card's edge, and the point on the edge where the critter peeks out.
    struct Spot: Equatable {
        let hide: CGPoint
        let peek: CGPoint
    }

    let frame: CGRect
    let spots: [Spot]
}
