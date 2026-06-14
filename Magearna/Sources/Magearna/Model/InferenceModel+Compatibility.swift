//
//  InferenceModel+Compatibility.swift
//  Magearna
//
//  Created by Lucka on 2026-06-12.
//

public extension InferenceModel {
    enum Compatibility : Sendable {
        case compatible
        case inefficient
        case incompatible
    }
}
