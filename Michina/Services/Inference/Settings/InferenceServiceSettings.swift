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
    let executionProvider = ExecutionProviderSettings.shared
    
    var preloadModels: [ InferenceModel ] {
        didSet {
            storage.preloadModels = preloadModels
                .map(\.id)
                .joined(separator: ",")
        }
    }
    
    var immichAppEndpointURL: URL? {
        didSet { storage.immichAppEndpointURL = immichAppEndpointURL }
    }
    
    var persistOptimizations: Bool {
        didSet { storage.persistOptimizations = persistOptimizations }
    }
    
    var loadedLifespan: Int {
        didSet { storage.loadedLifespan = loadedLifespan }
    }
    
    private let storage = Storage()
    
    private init() {
        self.preloadModels = storage.preloadModels
            .split(separator: ",")
            .compactMap(InferenceModel.find(id:))
        self.immichAppEndpointURL = storage.immichAppEndpointURL
        self.persistOptimizations = storage.persistOptimizations
        self.loadedLifespan = storage.loadedLifespan
    }
}

extension InferenceServiceSettings {
    static let shared = InferenceServiceSettings()
}

extension InferenceServiceSettings {
    var immichAppEndpoint: InferenceModelSuite.Provider.ImmichAppEndpoint {
        if let immichAppEndpointURL {
            .init(baseURL: immichAppEndpointURL)
        } else {
            .default
        }
    }
}

extension InferenceServiceSettings {
    func inferenceSessionOptions(
        for compatibility: InferenceModel.Compatibility
    ) -> InferenceSession.Options {
        return .init(
            persistOptimizations: self.persistOptimizations,
            executionProvider: executionProvider.executionProvider(for: compatibility)
        )
    }
}

fileprivate extension InferenceServiceSettings {
    struct Storage {
        @AppStorage("InferenceService.PreloadModels")
        var preloadModels: String = ""
        
        @AppStorage("InferenceService.Endpoint.ImmichApp")
        var immichAppEndpointURL: URL?
        
        @AppStorage("InferenceService.Cache.Lifespan")
        var loadedLifespan = 300
        
        @AppStorage("InferenceService.Session.PersistOptimizations")
        var persistOptimizations = true
    }
}
