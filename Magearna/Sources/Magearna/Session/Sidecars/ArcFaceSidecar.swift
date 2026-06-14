//
//  ArcFaceSidecar.swift
//  Magearna
//
//  Created by Lucka on 2026-06-10.
//

import Foundation
import SwiftProtobuf

struct ArcFaceSidecar : Sendable {
    let supportsBatch: Bool
    
    let decodeMean: Float
    let decodeScale: Float
    
    init(model: InferenceModel, cacheDirectory: URL, isCoreMLExecutionProviderEnabled: Bool) throws {
        // Invalid shape for output feature '_513'. (Underlying error: MultiArray shape
        // (2 x 64 x 7 x 7) does not match the shape (1 x 64 x 7 x 7) specified in the model
        // description)
        supportsBatch = if model.suiteName == "buffalo_s", isCoreMLExecutionProviderEnabled {
            false
        } else {
            true
        }
        
        let modelData = try ONNXPartialModel(
            serializedBytes: Data(contentsOf: model.modelFileURL(in: cacheDirectory)),
            options: .discardUnknownFields(true)
        )
        
        var subAndMul = (sub: false, mul: false)
        for node in modelData.graph.node.prefix(8) where !subAndMul.mul || !subAndMul.sub {
            if node.name.starts(with: "Sub") || node.name.starts(with: "_minus") {
                subAndMul.sub = true
            } else if node.name.starts(with: "Mul") || node.name.starts(with: "_mul") {
                subAndMul.mul = true
            }
        }
        (self.decodeMean, self.decodeScale) = if subAndMul.sub, subAndMul.mul {
            (0, 1)
        } else {
            (127.5, 1 / 127.5)
        }
    }
}
