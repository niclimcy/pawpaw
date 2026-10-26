//
//  GameTarget.swift
//  pawpaw
//

import CoreGraphics
import Foundation

/// A piece of prey. Positions are normalized (0...1) so the view can map them to any screen size.
struct GameTarget: Equatable {
    let id: UUID
    let kind: TargetKind
    let start: CGPoint
    /// Stop-and-go journey, one leg after another.
    let legs: [PathLeg]

    /// Total time on screen: all travel plus every freeze.
    var lifetime: TimeInterval {
        legs.reduce(0) { $0 + $1.travel + $1.pause }
    }
}
