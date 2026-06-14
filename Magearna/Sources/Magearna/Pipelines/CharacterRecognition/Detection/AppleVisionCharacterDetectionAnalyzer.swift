//
//  AppleVisionCharacterDetectionAnalyzer.swift
//  Magearna
//
//  Created by Lucka on 2026-06-12.
//

import CoreImage
import Vision

struct AppleVisionCharacterDetectionAnalyzer : CharacterDetectionFunction {
    func detect(
        image: CIImage,
        minimalConfidence: Float,
        maximalResolution: Int
    ) async throws -> CharacterDetectionFunction.Output {
        try await ImageRequestHandler(image)
            .perform(StaticConfigurations.request)
            .compactMap { observation in
                guard observation.confidence >= minimalConfidence else {
                    return nil
                }
                return .init(
                    confidence: observation.confidence,
                    // TODO: The output points feels like scaled, check
                    item: .init(
                        topLeft: observation.topLeft
                            .verticallyFlipped()
                            .toImageCoordinates(image.extent.size),
                        topRight: observation.topRight
                            .verticallyFlipped()
                            .toImageCoordinates(image.extent.size),
                        bottomRight: observation.bottomRight
                            .verticallyFlipped()
                            .toImageCoordinates(image.extent.size),
                        bottomLeft: observation.bottomLeft
                            .verticallyFlipped()
                            .toImageCoordinates(image.extent.size)
                    )
                )
            }
    }
}

fileprivate extension AppleVisionCharacterDetectionAnalyzer {
    enum StaticConfigurations {
        static let request: DetectTextRectanglesRequest = {
            var request = DetectTextRectanglesRequest(.revision1)
            request.reportCharacterBoxes = false
            return request
        }()
    }
}
