//
//  GameTarget.swift
//  pawpaw
//

import CoreGraphics
import Foundation

/// Positions are normalized (0...1) so the view can map them to any size.
struct GameTarget: Equatable {
    let id: UUID
    let kind: TargetKind
    let start: CGPoint
    let legs: [PathLeg]
    /// Time spent waiting off-screen at `start` before the first leg.
    var leadIn: TimeInterval = 0

    var lifetime: TimeInterval {
        legs.reduce(leadIn) { $0 + $1.travel + $1.pause }
    }
}
