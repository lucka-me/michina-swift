//
//  InferenceModelSuite+Provider.swift
//  Magearna
//
//  Created by Lucka on 2026-06-10.
//

import Foundation

public extension InferenceModelSuite {
    enum Provider : Sendable {
        case immichApp
        case rapidOCR
        
        case apple
    }
}

public extension InferenceModelSuite.Provider {
    @inlinable var isBuiltin: Bool {
        switch self {
        case .immichApp, .rapidOCR: false
        case .apple: true
        }
    }
}

public extension InferenceModelSuite {
    @inlinable var isBuiltin: Bool {
        provider.isBuiltin
    }
}
