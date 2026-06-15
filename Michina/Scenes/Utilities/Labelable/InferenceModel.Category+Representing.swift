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
        case .detection: "InferenceModel.Category.Detection"
        case .recognition: "InferenceModel.Category.Recognition"
        case .visual: "InferenceModel.Category.Visual"
        case .textual: "InferenceModel.Category.Textual"
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
