//
//  GameAreaView+BodyMotion.swift
//  pawpaw
//

import UIKit

extension GameAreaView {
    /// Small, repeating body movements layered on the path so each critter looks alive:
    /// wings that beat, legs that scuttle, a lizard that wriggles. All are additive, so they
    /// ride on top of the path animation. Fish and ribbons have their own swish and sway.
    func addBodyMotion(to critter: UIView, for target: GameTarget) {
        switch target.kind {
        case .butterfly:
            // Wings fold in and open out, seen from above as a narrowing of the body.
            addLoop(to: critter, keyPath: "transform.scale.x", values: [0, -0.55, 0], period: 0.18, key: "wingBeat")
        case .feather:
            addLoop(to: critter, keyPath: "transform.rotation.z", values: [0, 0.25, 0, -0.25, 0], period: 1.6, key: "sway")
        case .laser:
            addLoop(to: critter, keyPath: "transform.scale", values: [0, 0.12, 0], period: 0.5, key: "pulse")
        case .mouse:
            addStride(to: critter, target: target, keyPath: "transform.rotation.z", values: [0, 0.07, 0, -0.07, 0], period: 0.16)
        case .bug:
            addStride(to: critter, target: target, keyPath: "transform.rotation.z", values: [0, 0.1, 0, -0.1, 0], period: 0.1)
        case .lizard:
            addStride(to: critter, target: target, keyPath: "transform.rotation.z", values: [0, 0.14, 0, -0.14, 0], period: 0.2)
        case .cricket:
            // One springy stretch per hop.
            addStride(to: critter, target: target, keyPath: "transform.scale", values: [0, 0.16, 0], period: nil)
        case .bird:
            addStride(to: critter, target: target, keyPath: "transform.scale", values: [0, 0.1, 0], period: 0.2)
        case .fish, .ribbon:
            break
        }
    }

    private func addLoop(to critter: UIView, keyPath: String, values: [Double], period: TimeInterval, key: String) {
        let loop = CAKeyframeAnimation(keyPath: keyPath)
        loop.isAdditive = true
        loop.values = values
        loop.duration = period
        loop.repeatCount = .infinity
        loop.timingFunctions = Array(repeating: CAMediaTimingFunction(name: .easeInEaseOut), count: values.count - 1)
        critter.layer.add(loop, forKey: key)
    }

    /// Repeats `values` only while the critter is travelling, so a frozen critter stays still.
    /// With no `period`, plays once per leg.
    private func addStride(
        to critter: UIView,
        target: GameTarget,
        keyPath: String,
        values: [Double],
        period: TimeInterval?
    ) {
        let now = critter.layer.convertTime(CACurrentMediaTime(), from: nil)
        var start = target.leadIn
        for (index, leg) in target.legs.enumerated() {
            let cycle = period ?? leg.travel
            let stride = CAKeyframeAnimation(keyPath: keyPath)
            stride.isAdditive = true
            stride.values = values
            stride.duration = cycle
            stride.repeatCount = Float(leg.travel / cycle)
            stride.beginTime = now + start
            critter.layer.add(stride, forKey: "stride.\(keyPath).\(index)")
            start += leg.travel + leg.pause
        }
    }
}
