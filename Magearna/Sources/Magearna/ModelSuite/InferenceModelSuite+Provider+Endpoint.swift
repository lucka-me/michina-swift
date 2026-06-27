//
//  InferenceModelSuite+Provider+Endpoint.swift
//  Magearna
//
//  Created by Lucka on 2026-06-27.
//

import Foundation

public extension InferenceModelSuite.Provider {
    protocol Endpoint : Sendable {
        func homepageURL(of suite: InferenceModelSuite) -> URL
    }
    
    protocol ExternalEndpoint : Endpoint {
        func fetch(
            suite: InferenceModelSuite,
            to cacheDirectory: URL,
            with taskScheduling: some ConstrainedTaskScheduling,
            reporting progress: Progress?
        ) async throws
    }
    
    protocol MirrorableEndpoint : Endpoint {
        init(baseURL: URL)
    }
}
