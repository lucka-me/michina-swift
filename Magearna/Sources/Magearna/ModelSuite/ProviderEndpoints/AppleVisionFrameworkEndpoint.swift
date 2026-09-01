//
//  AppleVisionFrameworkEndpoint.swift
//  Magearna
//
//  Created by Lucka on 2026-06-10.
//

import Foundation

public extension InferenceModelSuite.Provider {
    @available(macOS 15.0, *)
    struct AppleVisionFrameworkEndpoint : Endpoint {
        public static let provider = InferenceModelSuite.Provider.apple
        
        private init() {
            
        }
        
        public func homepageURL(of suite: InferenceModelSuite) -> URL {
            .init(string: "https://developer.apple.com/documentation/vision")!
        }
    }
}

@available(macOS 15.0, *)
public extension InferenceModelSuite.Provider.AppleVisionFrameworkEndpoint {
    static let `default` = Self.init()
}

@available(macOS 15.0, *)
public extension InferenceModelSuite.Provider.Endpoint where
Self == InferenceModelSuite.Provider.AppleVisionFrameworkEndpoint
{
    @inlinable static var apple: Self {
        .default
    }
}
