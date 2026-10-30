//
//  CatFace.swift
//  pawpaw
//

import Foundation

enum CatFace: String, Codable, CaseIterable {
    case orange
    case gray
    case black
    case white
    case calico
    case siamese

    var imageName: String {
        "cat_\(rawValue)"
    }

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
