//
//  InferenceModel+Category.swift
//  Magearna
//
//  Created by Lucka on 2026-05-19.
//

public extension InferenceModel {
    enum Category : String {
        case detection
        case recognition
        case visual
        case textual
    }
}

extension InferenceModel.Category : Identifiable {
    public var id: RawValue {
        rawValue
    }
}

extension InferenceModel.Category : CaseIterable, Codable, Hashable, Sendable {
    
}
