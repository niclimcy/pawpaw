//
//  DifficultyTuner.swift
//  pawpaw
//

import Foundation

/// Speeds critters up after catches and slows them down after escapes and misses.
struct DifficultyTuner: Equatable {
    static let paceRange: ClosedRange<Double> = 0.75...1.3
    static let catchStep = 0.05
    static let escapeStep = 0.05
    /// Smaller than the other steps because cats tap a lot.
    static let missStep = 0.02

    /// Multiplier on critter speed; 1 is normal.
    private(set) var pace: Double = 1

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

    func lifetime(for base: TimeInterval) -> TimeInterval {
        base / pace
    }

    private mutating func adjust(by step: Double) {
        pace = min(max(pace + step, Self.paceRange.lowerBound), Self.paceRange.upperBound)
    }
}
