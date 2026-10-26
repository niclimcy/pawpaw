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
    let end: CGPoint
    let lifetime: TimeInterval
}
