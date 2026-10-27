//
//  CatProfile.swift
//  pawpaw
//

import Foundation

/// One cat in the household. Each cat keeps its own best scores and play stats.
struct CatProfile: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var emoji: String

    /// Longest name a profile can have.
    static let maxNameLength = 20
    /// Faces to choose from when adding a cat.
    static let emojiChoices = ["🐱", "😺", "😸", "😼", "🐈", "🐈‍⬛"]
    static let defaultName = "My Cat"

    init(id: UUID = UUID(), name: String, emoji: String = emojiChoices[0]) {
        self.id = id
        self.name = Self.cleaned(name) ?? Self.defaultName
        self.emoji = emoji
    }

    /// Trims a typed name and caps its length. Returns `nil` when nothing is left.
    static func cleaned(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxNameLength))
    }
}
