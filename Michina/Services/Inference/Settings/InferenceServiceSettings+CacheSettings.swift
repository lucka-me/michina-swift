//
//  InferenceServiceSettings+CacheSettings.swift
//  Michina
//
//  Created by Lucka on 2026-06-24.
//

import SwiftUI

extension InferenceServiceSettings {
    @MainActor
    @Observable
    final class CacheSettings {
        var lifespan: Int {
            didSet { storage.lifespan = lifespan }
        }
        
        private let storage = Storage()
        
        fileprivate init() {
            self.lifespan = storage.lifespan
        }
    }
}

extension InferenceServiceSettings.CacheSettings {
    static let shared = InferenceServiceSettings.CacheSettings()
}

fileprivate extension InferenceServiceSettings.CacheSettings {
    struct Storage {
        @AppStorage("InferenceService.Cache.Lifespan")
        var lifespan = 300
    }
}
