//
//  CatProfile.swift
//  pawpaw
//

import Foundation

struct CatProfile: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var face: CatFace
    var disabledKinds: Set<TargetKind>

    static let maxNameLength = 20
    static let defaultName = "My Cat"

    init(id: UUID = UUID(), name: String, face: CatFace = .orange, disabledKinds: Set<TargetKind> = []) {
        self.id = id
        self.name = Self.cleaned(name) ?? Self.defaultName
        self.face = face
        self.disabledKinds = disabledKinds
    }

    var enabledKinds: [TargetKind] {
        TargetKind.allCases.filter { !disabledKinds.contains($0) }
    }

    /// At least one critter that appears on every theme must stay enabled.
    static func isPlayable(disabledKinds: Set<TargetKind>) -> Bool {
        TargetKind.allCases.contains { $0.exclusiveTheme == nil && !disabledKinds.contains($0) }
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, face, disabledKinds
    }

    /// Tolerates legacy profiles: a missing or emoji `face` becomes `.orange`, missing `disabledKinds` is empty.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        face = (try? container.decodeIfPresent(CatFace.self, forKey: .face)) ?? .orange
        // Skip unknown kinds instead of failing the whole profile.
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

    /// Trimmed and length-capped; `nil` if empty.
    static func cleaned(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxNameLength))
    }
}
