//
//  PlayfieldTuning+Device.swift
//  pawpaw
//

import UIKit

extension PlayfieldTuning {
    static let pocketName = "Pocket Hunt"

    static var current: PlayfieldTuning {
        UIDevice.current.userInterfaceIdiom == .phone ? .pocket : .standard
    }

    var screenNote: String? {
        isPocket ? "📱 \(Self.pocketName) · plays best on a bigger screen" : nil
    }
}
