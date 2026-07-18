//
//  InferenceSession+Options.swift
//  Magearna
//
//  Created by Lucka on 2026-06-10.
//

public extension InferenceSession {
    struct Options : Sendable {
        public let persistOptimizations: Bool
        public let executionProvider: ExecutionProvider
        
        public init(
            persistOptimizations: Bool = true,
            executionProvider: ExecutionProvider = .coreML(format: .mlProgram)
        ) {
            self.persistOptimizations = persistOptimizations
            self.executionProvider = executionProvider
        }
    }
}

public extension InferenceSession.Options {
    enum ExecutionProvider : Sendable {
        case coreML(format: CoreMLFormat)
        case cpu
    }
}

public extension InferenceSession.Options.ExecutionProvider {
    enum CoreMLFormat : Sendable {
        case mlProgram
        case neuralNetwork
    }
}
