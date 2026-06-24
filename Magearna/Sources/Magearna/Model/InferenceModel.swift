//
//  InferenceModel.swift
//  Magearna
//
//  Created by Lucka on 2026-05-19.
//

import Foundation

public struct InferenceModel : Sendable {
    public let suiteCategory: InferenceModelSuite.Category
    public let suiteName: String
    
    public let category: Category
    
    public let provider: InferenceModelSuite.Provider
    public let compatibility: Compatibility
    
    internal init(
        suiteCategory: InferenceModelSuite.Category,
        suiteName: String,
        category: Category,
        provider: InferenceModelSuite.Provider,
        compatibility: Compatibility
    ) {
        self.suiteCategory = suiteCategory
        self.suiteName = suiteName
        self.category = category
        self.provider = provider
        self.compatibility = compatibility
    }
}

extension InferenceModel : Hashable {
    public func hash(into hasher: inout Hasher) {
        suiteCategory.hash(into: &hasher)
        suiteName.hash(into: &hasher)
        category.hash(into: &hasher)
    }
}

extension InferenceModel : Identifiable {
    public var id: String {
        suiteCategory.rawValue + "/" + suiteName + "/" + category.rawValue
    }
}

public extension InferenceModel {
    @inlinable static func find(
        suiteCategory: InferenceModelSuite.Category,
        suiteName: String,
        modelCategory: Category
    ) -> InferenceModel? {
        InferenceModelSuite.all[suiteCategory]?
            .first(where: { $0.name == suiteName })?
            .models[modelCategory]
    }
    
    @inlinable static func find(id: some StringProtocol) -> InferenceModel? {
        let components = id.split(separator: "/")
        guard
            components.count == 3,
            let suiteCategory = InferenceModelSuite.Category(rawValue: .init(components[0])),
            let modelCategory = InferenceModel.Category(rawValue: .init(components[2]))
        else {
            return nil
        }
        return find(
            suiteCategory: suiteCategory,
            suiteName: .init(components[1]),
            modelCategory: modelCategory
        )
    }
}

public extension InferenceModel {
    @inlinable var isBuiltin: Bool {
        provider.isBuiltin
    }
    
    @inlinable var suite: InferenceModelSuite {
        .all[suiteCategory]!.first { $0.name == suiteName }!
    }
}

public extension InferenceModel {
    @inlinable func directoryURL(in cacheDirectory: URL) -> URL {
        cacheDirectory
            .appending(components: suiteCategory.rawValue, suiteName, category.rawValue)
    }
    
    @inlinable func modelFileURL(in cacheDirectory: URL) -> URL {
        directoryURL(in: cacheDirectory)
            .appending(component: "model")
            .appendingPathExtension("onnx")
    }
}
