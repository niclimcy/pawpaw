//
//  DifficultyTuner.swift
//  pawpaw
//

import Foundation

/// Adjusts the pace of a round to the cat. A cat that catches a lot gets quicker critters;
/// a cat that keeps missing gets slower ones, so play stays fun for kittens and seniors alike.
struct DifficultyTuner: Equatable {
    /// Slowest and fastest pace. 1 is the normal speed.
    static let paceRange: ClosedRange<Double> = 0.75...1.3
    /// How much one catch speeds things up.
    static let catchStep = 0.05
    /// How much a critter running away slows things down.
    static let escapeStep = 0.05
    /// How much a missed tap slows things down. Smaller, because cats tap a lot.
    static let missStep = 0.02

    /// Current pace multiplier. Above 1 means faster critters.
    private(set) var pace: Double = 1
    /// When false the pace always stays at 1.
    let isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    mutating func recordCatch() {
        adjust(by: Self.catchStep)
    }

    mutating func recordEscape() {
        adjust(by: -Self.escapeStep)
    }

    mutating func recordMiss() {
        adjust(by: -Self.missStep)
    }

    mutating func reset() {
        pace = 1
    }

    /// How long a critter stays on screen at the current pace. Shorter means it moves faster.
    func lifetime(for base: TimeInterval) -> TimeInterval {
        base / pace
    }

    private mutating func adjust(by step: Double) {
        guard isEnabled else { return }
        pace = min(max(pace + step, Self.paceRange.lowerBound), Self.paceRange.upperBound)
    }
}
