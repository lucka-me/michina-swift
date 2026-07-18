//
//  InferenceModel+Compatibility.swift
//  Magearna
//
//  Created by Lucka on 2026-06-12.
//

public extension InferenceModel {
    enum Compatibility : Equatable, Sendable {
        case efficientCoreML
        case inefficientCoreML
        case neuralNetworkCoreML
        case cpuOnly
    }
}
