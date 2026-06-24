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
        var timeToLive: Int {
            didSet { storage.timeToLive = timeToLive }
        }
        
        private let storage = Storage()
        
        fileprivate init() {
            self.timeToLive = storage.timeToLive
        }
    }
}

extension InferenceServiceSettings.CacheSettings {
    static let shared = InferenceServiceSettings.CacheSettings()
}

fileprivate extension InferenceServiceSettings.CacheSettings {
    struct Storage {
        @AppStorage("InferenceService.Cache.TimeToLive")
        var timeToLive = 300
    }
}
