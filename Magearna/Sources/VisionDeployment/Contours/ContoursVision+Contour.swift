//
//  ContoursVision+Contour.swift
//  Magearna
//
//  Created by Lucka on 2026-09-01.
//

import Vision

public extension ContoursVision {
    struct Contour {
        let normalizedBoundingBox: NormalizedRect
        let normalizedPath: CGPath
        let normalizedPoints: [ NormalizedPoint ]
    }
}

public extension ContoursVision.Contour {
    func boundingBox(in imageSize: CGSize) -> CGRect {
        normalizedBoundingBox.toImageCoordinates(imageSize)
    }
}

public extension ContoursVision.Contour {
    func contains(normalizedPoint: CGPoint) -> Bool {
        normalizedPath.contains(normalizedPoint)
    }
    
    func contains(normalizedPoint: NormalizedPoint) -> Bool {
        normalizedPath.contains(normalizedPoint.cgPoint)
    }
}
