//
//  AppleVisionFrameworkEndpoint.swift
//  Magearna
//
//  Created by Lucka on 2026-06-10.
//

import Foundation

enum AppleVisionFrameworkEndpoint : InferenceModelSuiteProviderEndpoint {
    static func fetch(
        suite: InferenceModelSuite,
        to cacheDirectory: URL,
        with taskScheduling: some ConstrainedTaskScheduling,
        reporting progress: Progress?
    ) async throws {
        
    }
    
    static func homepageURL(of suite: InferenceModelSuite) -> URL {
        .init(string: "https://developer.apple.com/documentation/vision")!
    }
}
