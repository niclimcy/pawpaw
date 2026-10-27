//
//  CatFace.swift
//  pawpaw
//

import Foundation

/// The drawn cat headshots a profile can wear, one per coat colour.
enum CatFace: String, Codable, CaseIterable {
    case orange
    case gray
    case black
    case white
    case calico
    case siamese

    /// Name of the SVG headshot in the asset catalog.
    var imageName: String {
        "cat_\(rawValue)"
    }

    /// Spoken name for VoiceOver.
    var title: String {
        switch self {
        case .orange: return "Orange tabby"
        case .gray: return "Gray tabby"
        case .black: return "Black cat"
        case .white: return "White cat"
        case .calico: return "Calico"
        case .siamese: return "Siamese"
        }
    }
}
