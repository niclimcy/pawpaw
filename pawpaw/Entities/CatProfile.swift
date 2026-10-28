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
    /// Critters this cat doesn't enjoy, which never appear in its rounds. Empty means every critter plays.
    var disabledKinds: Set<TargetKind>

    /// Longest name a profile can have.
    static let maxNameLength = 20
    static let defaultName = "My Cat"

    init(id: UUID = UUID(), name: String, face: CatFace = .orange, disabledKinds: Set<TargetKind> = []) {
        self.id = id
        self.name = Self.cleaned(name) ?? Self.defaultName
        self.face = face
        self.disabledKinds = disabledKinds
    }

    /// Critters that may appear in this cat's rounds.
    var enabledKinds: [TargetKind] {
        TargetKind.allCases.filter { !disabledKinds.contains($0) }
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, face, disabledKinds
    }

    /// Profiles saved before headshots existed stored an emoji instead, so they get the orange tabby.
    /// Profiles saved before critter choices existed play with every critter.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        face = (try? container.decodeIfPresent(CatFace.self, forKey: .face)) ?? .orange
        // Unknown names (for example from a newer build) are skipped instead of failing the whole profile.
        let rawKinds = (try? container.decodeIfPresent([String].self, forKey: .disabledKinds)) ?? []
        disabledKinds = Set(rawKinds.compactMap(TargetKind.init(rawValue:)))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(face, forKey: .face)
        try container.encode(disabledKinds.map(\.rawValue).sorted(), forKey: .disabledKinds)
    }

    /// Trims a typed name and caps its length. Returns `nil` when nothing is left.
    static func cleaned(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxNameLength))
    }
}
