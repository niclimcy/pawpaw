//
//  OnboardingInteractor.swift
//  pawpaw
//

import CoreGraphics
import Foundation

final class OnboardingInteractor: OnboardingInteractorInputProtocol {
    // TODO: To remove after swift bug is resolved.
    nonisolated deinit {}

    private let profileStorage: ProfileStorage
    private let settings: SettingsStorage

    init(profileStorage: ProfileStorage, settings: SettingsStorage) {
        self.profileStorage = profileStorage
        self.settings = settings
    }

    var activeProfile: CatProfile {
        profileStorage.activeProfile
    }

    /// Renames the first cat rather than adding one, so there's no leftover "My Cat".
    func saveCat(name: String, face: CatFace) {
        profileStorage.update(profileStorage.activeProfile.id, name: name, face: face)
    }

    func completeOnboarding() {
        settings.hasCompletedOnboarding = true
    }

    func makePracticeTarget(kind: TargetKind) -> GameTarget {
        let start = Self.randomEdgePoint()
        return GameTarget(
            id: UUID(),
            kind: kind,
            start: start,
            legs: MovementPlanner.legs(
                from: start,
                style: kind.movementStyle,
                duration: PlayfieldTuning.onboarding.lifetime(
                    for: TimeInterval.random(in: kind.lifetimeRange))
            ),
            leadIn: MovementPlanner.leadIn(for: kind.movementStyle)
        )
    }

    private static func randomEdgePoint() -> CGPoint {
        let along = CGFloat.random(in: 0.15...0.85)
        let edge: CGFloat = Bool.random() ? 0 : 1
        // Mostly from the sides, since the field is wide.
        return Double.random(in: 0..<1) < 0.75
            ? CGPoint(x: edge, y: along) : CGPoint(x: along, y: edge)
    }
}
