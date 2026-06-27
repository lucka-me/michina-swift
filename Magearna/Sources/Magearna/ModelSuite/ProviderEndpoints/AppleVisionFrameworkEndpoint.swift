//
//  AppleVisionFrameworkEndpoint.swift
//  Magearna
//
//  Created by Lucka on 2026-06-10.
//

import Foundation

public extension InferenceModelSuite.Provider {
    struct AppleVisionFrameworkEndpoint : Endpoint {
        private init() {
            
        }
        
        public func homepageURL(of suite: InferenceModelSuite) -> URL {
            .init(string: "https://developer.apple.com/documentation/vision")!
        }
    }
}

public extension InferenceModelSuite.Provider.AppleVisionFrameworkEndpoint {
    static let `default` = Self.init()
}

public extension InferenceModelSuite.Provider.Endpoint where
Self == InferenceModelSuite.Provider.AppleVisionFrameworkEndpoint
{
    @inlinable static var apple: Self {
        .default
    }
}
