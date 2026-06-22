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
    
    var homepageURL: URL {
        provider.endpoint.homepageURL(of: self)
    }
    
    func fatch(
        to cacheDirectory: URL,
        with taskScheduling: some ConstrainedTaskScheduling,
        reporting progress: Progress? = nil
    ) async throws {
        try await provider.endpoint.fetch(
            suite: self,
            to: cacheDirectory,
            with: taskScheduling,
            reporting: progress
        )
    }
}

extension InferenceModelSuite.Provider {
    var endpoint: any InferenceModelSuiteProviderEndpoint.Type {
        switch self {
        case .immichApp: ImmichAppEndpoint.self
        case .rapidOCR: RapidOCREndpoint.self
        case .apple: AppleVisionFrameworkEndpoint.self
        }
    }
}

protocol InferenceModelSuiteProviderEndpoint {
    static func fetch(
        suite: InferenceModelSuite,
        to cacheDirectory: URL,
        with taskScheduling: some ConstrainedTaskScheduling,
        reporting progress: Progress?
    ) async throws
    
    static func homepageURL(of suite: InferenceModelSuite) -> URL
}
