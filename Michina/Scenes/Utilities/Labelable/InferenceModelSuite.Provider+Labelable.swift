//
//  InferenceModelSuite.Provider+Labelable.swift
//  Michina
//
//  Created by Lucka on 2026-06-10.
//

import Magearna
import SwiftUI

extension InferenceModelSuite.Provider : Labelable {
    var titleKey: LocalizedStringKey {
        switch self {
        case .immichApp: "Immich App"
        case .rapidOCR: "RapidOCR"
        case .apple: "Apple"
        }
    }
    
    var systemImage: String {
        switch self {
        case .immichApp: "camera.aperture"
        case .rapidOCR: "bolt.fill"
        case .apple: "eye"
        }
    }
}
