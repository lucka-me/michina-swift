//
//  ContoursVision+NormalizedContour.swift
//  Magearna
//
//  Created by Lucka on 2026-09-01.
//

import Vision

public extension ContoursVision {
    struct NormalizedContour {
        let boundingBox: CGRect
        let path: CGPath
        let points: [ CGPoint ]
    }
}

public extension ContoursVision.NormalizedContour {
    func boundingBox(in imageSize: CGSize) -> CGRect {
        if #available(macOS 15.0, *) {
            NormalizedRect(normalizedRect: boundingBox)
                .toImageCoordinates(imageSize)
        } else {
            VNImageRectForNormalizedRect(
                boundingBox,
                .init(imageSize.width),
                .init(imageSize.height)
            )
        }
    }
}

public extension ContoursVision.NormalizedContour {
    func contains(normalizedPoint: CGPoint) -> Bool {
        path.contains(normalizedPoint)
    }
}

extension ContoursVision.NormalizedContour {
    @available(macOS 15.0, *)
    init(_ source: ContoursObservation.Contour) {
        self.path = source.normalizedPath
        
        if #available(macOS 26.0, *) {
            self.boundingBox = source.boundingBox.cgRect
            self.points = source.points.map(\.cgPoint)
        } else {
            self.points = source.normalizedPoints.map {
                .init(x: CGFloat($0.x), y: CGFloat($0.y))
            }
            self.boundingBox = .init(including: self.points)
        }
    }
    
    init(_ source: VNContour) {
        self.path = source.normalizedPath
        self.points = source.normalizedPoints.map {
            .init(x: CGFloat($0.x), y: CGFloat($0.y))
        }
        self.boundingBox = .init(including: self.points)
    }
}

fileprivate extension CGRect {
    init(including points: [ CGPoint ]) {
        guard !points.isEmpty else {
            self = .zero
            return
        }
        
        let (bottomLeft, topRight) = points[1...]
            .reduce(
                into: (bottomLeft: points[0], topRight: points[0])
            ) { partial, point in
                partial.bottomLeft.x = min(partial.bottomLeft.x, point.x)
                partial.bottomLeft.y = min(partial.bottomLeft.y, point.y)
                
                partial.topRight.x = max(partial.topRight.x, point.x)
                partial.topRight.y = max(partial.topRight.y, point.y)
            }
        
        self.init(
            x: bottomLeft.x,
            y: bottomLeft.y,
            width: topRight.x - bottomLeft.x,
            height: topRight.y - bottomLeft.y
        )
    }
}
