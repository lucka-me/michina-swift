//
//  InferenceModelSuite+Category.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

public extension InferenceModelSuite {
    enum Category : String {
        case facialRecognition = "facial-recognition"
        case search = "clip"
        case characterRecognition = "ocr"
    }
}

extension InferenceModelSuite.Category : Identifiable  {
    public var id: RawValue {
        rawValue
    }
}

extension InferenceModelSuite.Category : CaseIterable, Codable, Hashable, Sendable  {
    
}

public extension InferenceModelSuite.Category {
    static var allOptionalCases: [ Self? ] {
        [ nil ] + allCases
    }
}
