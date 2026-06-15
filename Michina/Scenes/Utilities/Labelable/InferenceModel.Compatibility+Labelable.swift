//
//  InferenceModel.Compatibility+Labelable.swift
//  Michina
//
//  Created by Lucka on 2026-06-15.
//

import Magearna
import SwiftUI

extension InferenceModel.Compatibility : Labelable {
    var titleKey: LocalizedStringKey {
        switch self {
        case .compatible: "InferenceModel.Compatibility.Compatible"
        case .inefficient: "InferenceModel.Compatibility.Inefficient"
        case .incompatible: "InferenceModel.Compatibility.Incompatible"
        }
    }
    
    var systemImage: String {
        switch self {
        case .compatible: "checkmark"
        case .inefficient: "exclamationmark"
        case .incompatible: "xmark"
        }
    }
}

extension InferenceModel.Compatibility {
    var color: Color {
        switch self {
        case .compatible: .green
        case .inefficient: .orange
        case .incompatible: .red
        }
    }
}
