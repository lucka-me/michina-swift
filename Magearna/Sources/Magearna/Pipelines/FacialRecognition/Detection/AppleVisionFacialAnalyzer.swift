//
//  AppleVisionFacialAnalyzer.swift
//  Magearna
//
//  Created by Lucka on 2026-05-29.
//

import CoreImage
import Vision

struct AppleVisionFacialAnalyzer : FaceDetectionFunction {
    func detect(image: CIImage, minimalConfidence: Float) async throws -> Output {
        let handler = ImageRequestHandler(image)
        
        var observations = try await detectRectangles(
            with: handler,
            minimalConfidence: minimalConfidence
        )
        guard !observations.isEmpty else {
            return [ ]
        }
        
        observations = try await detectLandmarks(from: observations, with: handler)
        return parse(observations: observations, in: image.extent.size)
    }
}

fileprivate extension AppleVisionFacialAnalyzer {
    func detectRectangles(
        with handler: ImageRequestHandler,
        minimalConfidence: Float
    ) async throws -> [ FaceObservation ] {
        try await handler
            .perform(DetectFaceRectanglesRequest(.revision3))
            .filter {
                $0.confidence >= minimalConfidence
            }
    }
    
    func detectLandmarks(
        from rectangles: [ FaceObservation ],
        with handler: ImageRequestHandler
    ) async throws -> [ FaceObservation ] {
        var request = DetectFaceLandmarksRequest(.revision3)
        request.inputFaceObservations = rectangles
        return try await handler.perform(request)
    }
}

fileprivate extension AppleVisionFacialAnalyzer {
    func parse(observations: [ FaceObservation ], in imageSize: CGSize) -> Output {
        observations.compactMap { observation in
            let boundingBox = observation.boundingBox
                .verticallyFlipped()
                .toImageCoordinates(imageSize)
            
            let landmarks: [ CGPoint ]
            if let observedLandmarks = observation.landmarks {
                landmarks = observedLandmarks.points.map {
                    let pointOnFace = $0
                        .verticallyFlipped()
                        .toImageCoordinates(boundingBox.size)
                    return .init(
                        x: boundingBox.origin.x + pointOnFace.x,
                        y: boundingBox.origin.y + pointOnFace.y
                    )
                }
            } else {
                landmarks = [ ]
            }
            
            return .init(
                confidence: observation.confidence,
                item: .init(
                    boundingBox: boundingBox,
                    landmarks: landmarks
                )
            )
        }
    }
}

fileprivate extension FaceObservation.Landmarks2D {
    var points: [ NormalizedPoint ] {
        guard
            let leftEyeCenter = leftEye.center,
            let rightEyeCenter = rightEye.center,
            let noseCenter = noseCrest.center,
            let (mouthLeft, mouthRight) = outerLips.verticalEndpoints
        else {
            return [ ]
        }
        return [
            leftEyeCenter,
            rightEyeCenter,
            noseCenter,
            mouthLeft,
            mouthRight,
        ]
    }
}

fileprivate extension FaceObservation.Landmarks2D.Region {
    var center: NormalizedPoint? {
        guard var accumulated = points.first?.cgPoint else {
            return nil
        }
        
        for point in points[1...] {
            accumulated.x += point.x
            accumulated.y += point.y
        }
        
        return .init(
            x: accumulated.x / .init(points.count),
            y: accumulated.y / .init(points.count)
        )
    }
    
    var verticalEndpoints: (left: NormalizedPoint, right: NormalizedPoint)? {
        guard !points.isEmpty else {
            return nil
        }
        let sorted = points.sorted(using: KeyPathComparator(\.x))
        return (sorted.first!, sorted.last!)
    }
    
}
