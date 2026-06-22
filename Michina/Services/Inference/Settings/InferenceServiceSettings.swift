//
//  InferenceServiceSettings.swift
//  Michina
//
//  Created by Lucka on 2026-06-04.
//

import Foundation
import Magearna
import SwiftUI

@MainActor
@Observable
final class InferenceServiceSettings {
    let session = SessionSettings()
    let cache = CacheSettings()
    
    private let storage = Storage()
    
    private init() {
    }
}

extension InferenceServiceSettings {
    static let shared = InferenceServiceSettings()
}

extension InferenceServiceSettings {
    @MainActor
    @Observable
    final class CacheSettings {
        var timeToLive: Int {
            didSet { storage.timeToLive = timeToLive }
        }
        
        private let storage = Storage()
        
        fileprivate init() {
            self.timeToLive = storage.timeToLive
        }
    }
}

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
    var inferenceSessionOptions: InferenceSession.Options {
        .init(
            persistOptimizations: self.persistOptimizations,
            executionProviderPreference: self.executionProviderPreference
        )
    }
}

fileprivate extension InferenceServiceSettings {
    struct Storage {
    }
}

fileprivate extension InferenceServiceSettings.CacheSettings {
    struct Storage {
        @AppStorage("InferenceSession.Cache.TimeToLive") var timeToLive = 300
    }
}

fileprivate extension InferenceServiceSettings.SessionSettings {
    struct Storage {
        @AppStorage("InferenceSession.Session.PersistOptimizations")
        var persistOptimizations = true
        
        @AppStorage("InferenceSession.Session.PreferCoreML")
        var preferCoreML = true
        
        @AppStorage("InferenceSession.Session.PreferEfficiency")
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
