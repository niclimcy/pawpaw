//
//  PlayfieldTuning.swift
//  pawpaw
//

import CoreGraphics
import Foundation

/// iPhone plays Pocket Hunt, tuned for the small screen; iPad keeps `standard`.
struct PlayfieldTuning: Equatable {
    let targetSize: CGFloat
    let hidingSpotSize: CGFloat
    let maxActiveTargets: Int
    let hidingSpotCount: Int
    let hitSlop: CGFloat
    let lureHitSlop: CGFloat
    /// How far a missed tap scares the nearest critter.
    let startleRange: CGFloat
    /// Multiplier on critter speed.
    let pace: Double
    let prefersLandscape: Bool
    /// Round length until the owner picks one.
    let defaultMode: SessionMode

    static let standard = PlayfieldTuning(
        targetSize: 126,
        hidingSpotSize: 170,
        maxActiveTargets: 2,
        hidingSpotCount: 2,
        hitSlop: 28,
        lureHitSlop: 40,
        startleRange: 220,
        pace: 1,
        prefersLandscape: false,
        defaultMode: .standard
    )

    static let pocket = PlayfieldTuning(
        targetSize: 126,
        hidingSpotSize: 130,
        maxActiveTargets: 1,
        hidingSpotCount: 1,
        hitSlop: 44,
        lureHitSlop: 56,
        startleRange: 140,
        pace: 0.85,
        prefersLandscape: true,
        defaultMode: .short
    )

    /// Onboarding's practice field.
    static let onboarding = PlayfieldTuning(
        targetSize: 80,
        hidingSpotSize: 0,
        maxActiveTargets: 1,
        hidingSpotCount: 0,
        hitSlop: 24,
        lureHitSlop: 24,
        startleRange: 120,
        pace: 0.8,
        prefersLandscape: false,
        defaultMode: .short
    )

    var isPocket: Bool {
        self == .pocket
    }

    func lifetime(for base: TimeInterval) -> TimeInterval {
        base / pace
    }
}
