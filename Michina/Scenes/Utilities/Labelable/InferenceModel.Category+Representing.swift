//
//  InferenceModel.Category+Representing.swift
//  Michina
//
//  Created by Lucka on 2026-06-06.
//

import Magearna
import SwiftUI

extension InferenceModel.Category : Labelable {
    var titleKey: LocalizedStringKey {
        switch self {
        case .detection: "Detection"
        case .recognition: "Recognition"
        case .visual: "Visual"
        case .textual: "Textual"
        }
    }
    
    var systemImage: String {
        switch self {
        case .detection: "dot.viewfinder"
        case .recognition: "sparkle.magnifyingglass"
        case .visual: "eye"
        case .textual: "text.bubble"
        }
    }
}
