//
//  InferenceServiceSettings+SessionSettings.swift
//  Michina
//
//  Created by Lucka on 2026-06-24.
//

import Magearna
import SwiftUI

extension InferenceServiceSettings {
    @MainActor
    @Observable
    final class SessionSettings {
        var persistOptimizations: Bool {
            didSet { storage.persistOptimizations = persistOptimizations }
        }
        
        var preferCoreML: Bool {
            didSet { storage.preferCoreML = preferCoreML }
        }
        
        var preferEfficiency: Bool {
            didSet { storage.preferEfficiency = preferEfficiency }
        }
        
        private let storage = Storage()
        
        fileprivate init() {
            self.persistOptimizations = storage.persistOptimizations
            self.preferCoreML = storage.preferCoreML
            self.preferEfficiency = storage.preferEfficiency
        }
    }
}

extension InferenceServiceSettings.SessionSettings {
    static let shared = InferenceServiceSettings.SessionSettings()
}

extension InferenceServiceSettings.SessionSettings {
    var inferenceSessionOptions: InferenceSession.Options {
        .init(
            persistOptimizations: self.persistOptimizations,
            executionProviderPreference: self.executionProviderPreference
        )
    }
}

fileprivate extension InferenceServiceSettings.SessionSettings {
    struct Storage {
        @AppStorage("InferenceService.Session.PersistOptimizations")
        var persistOptimizations = true
        
        @AppStorage("InferenceService.Session.PreferCoreML")
        var preferCoreML = true
        
        @AppStorage("InferenceService.Session.PreferEfficiency")
        var preferEfficiency = true
    }
    
    var executionProviderPreference: InferenceSession.Options.ExecutionProviderPreference {
        if preferCoreML {
            if preferEfficiency {
                .efficientCoreML
            } else {
                .coreML
            }
        } else {
            .alwaysCPU
        }
    }
}

