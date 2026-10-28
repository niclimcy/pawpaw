//
//  Log.swift
//  pawpaw
//

import Foundation
import os

/// Unified logging, so failures that the app recovers from quietly still show up in Console.
enum Log {
    private static let storage = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pawpaw", category: "storage")

    /// Saved data couldn't be read or written. The app carries on with a safe default.
    static func storageFailure(_ message: String, error: Error) {
        storage.error("\(message, privacy: .public): \(String(describing: error), privacy: .public)")
    }

    /// Saved data had to be repaired.
    static func storageNotice(_ message: String) {
        storage.notice("\(message, privacy: .public)")
    }
}
