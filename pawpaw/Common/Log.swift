//
//  Log.swift
//  pawpaw
//

import Foundation
import os

enum Log {
    private static let storage = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pawpaw", category: "storage")

    static func storageFailure(_ message: String, error: Error) {
        storage.error("\(message, privacy: .public): \(String(describing: error), privacy: .public)")
    }

    static func storageNotice(_ message: String) {
        storage.notice("\(message, privacy: .public)")
    }
}
