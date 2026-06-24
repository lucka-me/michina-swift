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
    
    private let storage = Storage()
    
    private init() {
    }
}

extension InferenceServiceSettings {
    static let shared = InferenceServiceSettings()
}

fileprivate extension InferenceServiceSettings {
    struct Storage {
    }
}
