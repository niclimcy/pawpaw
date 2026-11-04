//
//  PlayfieldTuning+Device.swift
//  pawpaw
//

import UIKit

extension PlayfieldTuning {
    static var current: PlayfieldTuning {
        UIDevice.current.userInterfaceIdiom == .phone ? .pocket : .standard
    }

    var screenNote: String? {
        isPocket ? "Plays best on a bigger screen" : nil
    }
}
