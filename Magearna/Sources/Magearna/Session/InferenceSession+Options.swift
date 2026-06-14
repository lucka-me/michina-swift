//
//  InferenceSession+Options.swift
//  Magearna
//
//  Created by Lucka on 2026-06-10.
//

public extension InferenceSession {
    struct Options : Sendable {
        public let persistOptimizations: Bool
        public let executionProviderPreference: ExecutionProviderPreference
        
        public init(
            persistOptimizations: Bool = true,
            executionProviderPreference: ExecutionProviderPreference = .coreML
        ) {
            self.persistOptimizations = persistOptimizations
            self.executionProviderPreference = executionProviderPreference
        }
    }
}

public extension InferenceSession.Options {
    enum ExecutionProviderPreference : Sendable {
        case coreML
        case efficientCoreML
        case alwaysCPU
    }
}
