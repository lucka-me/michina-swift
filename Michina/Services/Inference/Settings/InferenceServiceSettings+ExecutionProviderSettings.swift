//
//  InferenceServiceSettings+ExecutionProviderSettings.swift
//  Michina
//
//  Created by Lucka on 2026-07-18.
//

import Magearna
import SwiftUI

extension InferenceServiceSettings {
    @MainActor
    @Observable
    final class ExecutionProviderSettings {
        var efficientCoreML: Option {
            didSet { storage.efficientCoreML = efficientCoreML }
        }
        
        var inefficientCoreML: Option {
            didSet { storage.inefficientCoreML = inefficientCoreML }
        }
        
        var neuralNetworkCoreML: Option {
            didSet { storage.neuralNetworkCoreML = neuralNetworkCoreML }
        }
        
        private let storage = Storage()
        
        fileprivate init() {
            self.efficientCoreML = storage.efficientCoreML
            self.inefficientCoreML = storage.inefficientCoreML
            self.neuralNetworkCoreML = storage.neuralNetworkCoreML
        }
    }
}

extension InferenceServiceSettings.ExecutionProviderSettings {
    static let shared = InferenceServiceSettings.ExecutionProviderSettings()
}

extension InferenceServiceSettings.ExecutionProviderSettings {
    enum Option : String, CaseIterable, Identifiable {
        case coreMLWithMLProgram = "CoreML+MLProgram"
        case coreMLWithNeuralNetwork = "CoreML+NeuralNetwork"
        case cpu = "CPU"
        
        var id: RawValue {
            rawValue
        }
    }
}

extension InferenceServiceSettings.ExecutionProviderSettings {
    func executionProvider(
        for compatibility: InferenceModel.Compatibility
    ) -> InferenceSession.Options.ExecutionProvider {
        switch compatibility {
        case .efficientCoreML: efficientCoreML.executionProvider
        case .inefficientCoreML: inefficientCoreML.executionProvider
        case .neuralNetworkCoreML: neuralNetworkCoreML.executionProvider
        case .cpuOnly: .cpu
        }
    }
}

extension InferenceServiceSettings.ExecutionProviderSettings.Option {
    static let casesForNeuralNetwork: [ Self ] = [ .coreMLWithNeuralNetwork, .cpu ]
    
    var titleKey: LocalizedStringKey {
        switch self {
        case .coreMLWithMLProgram:
            "InferenceServiceSettings.ExecutionProviderSettings.Option.CoreML+MLProgram"
        case .coreMLWithNeuralNetwork:
            "InferenceServiceSettings.ExecutionProviderSettings.Option.CoreML+NeuralNetwork"
        case .cpu:
            "InferenceServiceSettings.ExecutionProviderSettings.Option.CPU"
        }
    }
}

fileprivate extension InferenceServiceSettings.ExecutionProviderSettings {
    struct Storage {
        @AppStorage("InferenceService.Session.ExecutionProvider.EfficientCoreML")
        var efficientCoreML = Option.coreMLWithMLProgram
        
        @AppStorage("InferenceService.Session.ExecutionProvider.InefficientCoreML")
        var inefficientCoreML = Option.coreMLWithNeuralNetwork
        
        @AppStorage("InferenceService.Session.ExecutionProvider.NeuralNetworkCoreML")
        var neuralNetworkCoreML = Option.coreMLWithNeuralNetwork
    }
}

fileprivate extension InferenceServiceSettings.ExecutionProviderSettings.Option {
    var executionProvider: InferenceSession.Options.ExecutionProvider {
        switch self {
        case .coreMLWithMLProgram: .coreML(format: .mlProgram)
        case .coreMLWithNeuralNetwork: .coreML(format: .neuralNetwork)
        case .cpu: .cpu
        }
    }
}
