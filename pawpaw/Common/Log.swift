//
//  Log.swift
//  pawpaw
//

import Foundation
import os

/// Nonisolated so callbacks off the main actor, like a geometry request's error handler, can log.
nonisolated enum Log {
    private static let storage = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "pawpaw", category: "storage")
    private static let layout = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "pawpaw", category: "layout")

    static func storageFailure(_ message: String, error: Error) {
        storage.error(
            "\(message, privacy: .public): \(String(describing: error), privacy: .public)")
    }

    static func storageNotice(_ message: String) {
        storage.notice("\(message, privacy: .public)")
    }

    static func layoutNotice(_ message: String, error: Error) {
        layout.notice(
            "\(message, privacy: .public): \(String(describing: error), privacy: .public)")
    }
}
