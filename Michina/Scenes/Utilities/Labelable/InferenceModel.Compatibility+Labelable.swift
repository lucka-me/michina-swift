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
        case .efficientCoreML: "InferenceModel.Compatibility.EfficientCoreML"
        case .inefficientCoreML: "InferenceModel.Compatibility.InefficientCoreML"
        case .neuralNetworkCoreML: "InferenceModel.Compatibility.NeuralNetworkCoreML"
        case .cpuOnly: "InferenceModel.Compatibility.CPUOnly"
        }
    }
    
    var systemImage: String {
        switch self {
        case .efficientCoreML: "hare"
        case .inefficientCoreML: "tortoise"
        case .neuralNetworkCoreML: "brain"
        case .cpuOnly: "cpu"
        }
    }
}

extension InferenceModel.Compatibility {
    var helpTitleKey: LocalizedStringKey {
        switch self {
        case .efficientCoreML: "InferenceModel.Compatibility.EfficientCoreML.Help"
        case .inefficientCoreML: "InferenceModel.Compatibility.InefficientCoreML.Help"
        case .neuralNetworkCoreML: "InferenceModel.Compatibility.NeuralNetworkCoreML.Help"
        case .cpuOnly: "InferenceModel.Compatibility.CPUOnly.Help"
        }
    }
    
    var color: Color {
        switch self {
        case .efficientCoreML: .green
        case .inefficientCoreML: .yellow
        case .neuralNetworkCoreML: .orange
        case .cpuOnly: .red
        }
    }
}
