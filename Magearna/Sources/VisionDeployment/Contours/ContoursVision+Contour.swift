//
//  ContoursVision+Contour.swift
//  Magearna
//
//  Created by Lucka on 2026-09-01.
//

import Vision

public extension ContoursVision {
    struct Contour {
        let normalizedBoundingBox: CGRect
        let normalizedPath: CGPath
        let normalizedPoints: [ SIMD2<Double> ]
    }
}

public extension ContoursVision.Contour {
    func boundingBox(in imageSize: CGSize) -> CGRect {
        if #available(macOS 15.0, *) {
            NormalizedRect(normalizedRect: normalizedBoundingBox)
                .toImageCoordinates(imageSize)
        } else {
            VNImageRectForNormalizedRect(
                normalizedBoundingBox,
                .init(imageSize.width),
                .init(imageSize.height)
            )
        }
    }
}

public extension ContoursVision.Contour {
    func contains(normalizedPoint: CGPoint) -> Bool {
        normalizedPath.contains(normalizedPoint)
    }
}

extension ContoursVision.Contour {
    @available(macOS 15.0, *)
    init(_ source: ContoursObservation.Contour) {
        self.normalizedPath = source.normalizedPath
        
        if #available(macOS 26.0, *) {
            self.normalizedBoundingBox = source.boundingBox.cgRect
            self.normalizedPoints = source.points.map { .init(x: $0.x, y: $0.y) }
        } else {
            self.normalizedBoundingBox = self.normalizedPath.boundingBox
            self.normalizedPoints = source.normalizedPoints.map(SIMD2.init)
        }
    }
    
    init(_ source: VNContour) {
        self.normalizedPath = source.normalizedPath
        self.normalizedBoundingBox = self.normalizedPath.boundingBox
        self.normalizedPoints = source.normalizedPoints.map(SIMD2.init)
    }
}
