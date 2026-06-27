//
//  InferenceSession+Sidecar.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

import ONNXRuntime

extension InferenceSession {
    enum Sidecar : Sendable {
        case retinaFace(RetinaFace.Sidecar)
        case arcFace(ArcFace.Sidecar)
        
        case visualSearch(VisualSearchInferencePipeline.Sidecar)
        case textualSearch(TextualSearchInferencePipeline.Sidecar)
        
        case rapidCharacterRecognition(RapidCharacterRecognition.Sidecar)
    }
}

extension InferenceSession.Sidecar {
    static func create(
        model: InferenceModel,
        cacheDirectory: URL,
        outputNamesCount: Int,
        isCoreMLExecutionProviderEnabled: Bool
    ) throws -> Self? {
        switch model.suiteCategory {
        case .facialRecognition:
            switch model.category {
            case .detection: .retinaFace(
                .init(outputNamesCount: outputNamesCount)
            )
            case .recognition: .arcFace(
                try .init(
                    model: model,
                    cacheDirectory: cacheDirectory,
                    isCoreMLExecutionProviderEnabled: isCoreMLExecutionProviderEnabled
                )
            )
            default: fatalError("Unsupported sidecar: \(model.id)")
            }
        case .search:
            switch model.category {
            case .visual: .visualSearch(
                try .init(model: model, cacheDirectory: cacheDirectory)
            )
            case .textual: .textualSearch(
                try .init(model: model, cacheDirectory: cacheDirectory)
            )
            default: fatalError("Unsupported sidecar: \(model.id)")
            }
        case .characterRecognition:
            switch model.category {
            case .recognition: .rapidCharacterRecognition(
                try .init(model: model, cacheDirectory: cacheDirectory)
            )
            default: nil
            }
        }
    }
}
