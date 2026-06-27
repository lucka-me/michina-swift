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
    let session = SessionSettings.shared
    let cache = CacheSettings.shared
    
    var preloadModels: [ InferenceModel ] {
        didSet {
            storage.preloadModels = preloadModels.map(\.id).joined(separator: ",")
        }
    }
    
    var immichAppEndpointURL: URL? {
        didSet {
            storage.immichAppEndpointURL = immichAppEndpointURL
        }
    }
    
    private let storage = Storage()
    
    private init() {
        self.preloadModels = storage.preloadModels
            .split(separator: ",")
            .compactMap(InferenceModel.find(id:))
        self.immichAppEndpointURL = storage.immichAppEndpointURL
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

fileprivate extension InferenceServiceSettings {
    struct Storage {
        @AppStorage("InferenceService.PreloadModels")
        var preloadModels: String = ""
        
        @AppStorage("InferenceService.Endpoint.ImmichApp")
        var immichAppEndpointURL: URL?
    }
}
