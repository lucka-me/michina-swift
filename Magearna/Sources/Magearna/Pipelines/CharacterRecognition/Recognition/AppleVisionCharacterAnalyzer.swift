//
//  AppleVisionCharacterAnalyzer.swift
//  Magearna
//
//  Created by Lucka on 2026-06-12.
//

import CoreImage
import Vision

actor AppleVisionCharacterAnalyzer :
    CharacterDetectionFunction,
    CharacterRecognitionFunction
{
    private var recognitionResults: [ RecognizedTextObservation ] = [ ]
    
    func detect(
        image: CIImage,
        minimalConfidence: Float,
        maximalResolution: Int
    ) async throws -> CharacterDetectionFunction.Output {
        self.recognitionResults = try await ImageRequestHandler(image)
            .perform(StaticConfigurations.request)
            .filter { $0.confidence >= minimalConfidence }
        
        let imageSize = image.extent.size
        return self.recognitionResults
            .map { observation in
                .init(
                    confidence: observation.confidence,
                    // TODO: The output shapes are weird, check
                    item: .init(
                        topLeft: observation.topLeft
                            .verticallyFlipped()
                            .toImageCoordinates(imageSize),
                        topRight: observation.topRight
                            .verticallyFlipped()
                            .toImageCoordinates(imageSize),
                        bottomRight: observation.bottomRight
                            .verticallyFlipped()
                            .toImageCoordinates(imageSize),
                        bottomLeft: observation.bottomLeft
                            .verticallyFlipped()
                            .toImageCoordinates(imageSize)
                    )
                )
            }
    }
    
    func recognize(
        boxes: [ Quadrilateral ],
        in image: CIImage,
        minimalConfidence: Float
    ) throws -> CharacterRecognitionFunction.Output {
        self.recognitionResults
            .map { observation in
                guard
                    let candidate = observation.topCandidates(1).first,
                    candidate.confidence >= minimalConfidence
                else {
                    return nil
                }
                return .init(confidence: candidate.confidence, item: candidate.string)
            }
    }
}

fileprivate extension AppleVisionCharacterAnalyzer {
    enum StaticConfigurations {
        static let request: RecognizeTextRequest = {
            var request = RecognizeTextRequest(.revision3)
            request.automaticallyDetectsLanguage = true
            request.usesLanguageCorrection = true
            request.recognitionLevel = .accurate
            return request
        }()
    }
}
