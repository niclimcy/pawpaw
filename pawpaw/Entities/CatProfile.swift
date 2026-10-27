//
//  CatProfile.swift
//  pawpaw
//

import Foundation

/// One cat in the household. Each cat keeps its own best scores and play stats.
struct CatProfile: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var face: CatFace

    /// Longest name a profile can have.
    static let maxNameLength = 20
    static let defaultName = "My Cat"

    init(id: UUID = UUID(), name: String, face: CatFace = .orange) {
        self.id = id
        self.name = Self.cleaned(name) ?? Self.defaultName
        self.face = face
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, face
    }

    /// Profiles saved before headshots existed stored an emoji instead, so they get the orange tabby.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        face = (try? container.decodeIfPresent(CatFace.self, forKey: .face)) ?? .orange
    }

    /// Trims a typed name and caps its length. Returns `nil` when nothing is left.
    static func cleaned(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxNameLength))
    }
}
