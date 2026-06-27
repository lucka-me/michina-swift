//
//  InferenceModelSuite.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

import Foundation

public struct InferenceModelSuite : Sendable {
    public let category: Category
    public let name: String
    
    public let provider: Provider
    
    public let models: [ InferenceModel.Category : InferenceModel ]
    
    internal init(
        category: Category,
        name: String,
        provider: Provider,
        models: [ InferenceModel.Category : InferenceModel ]
    ) {
        self.category = category
        self.name = name
        self.provider = provider
        self.models = models
    }
}

extension InferenceModelSuite : Equatable {
    public static func == (lhs: InferenceModelSuite, rhs: InferenceModelSuite) -> Bool {
        lhs.name == rhs.name && lhs.category == rhs.category
    }
}

extension InferenceModelSuite : Hashable {
    public func hash(into hasher: inout Hasher) {
        name.hash(into: &hasher)
        category.hash(into: &hasher)
    }
}

extension InferenceModelSuite : Identifiable {
    public var id: String {
        category.rawValue + "/" + name
    }
}

public extension InferenceModelSuite {
    @inlinable func directoryURL(in cacheDirectory: URL) -> URL {
        cacheDirectory
            .appending(components: category.rawValue, name)
    }
}
