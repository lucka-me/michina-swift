//
//  ContoursObservation.Contour+BackDeploy.swift
//  Magearna
//
//  Created by Lucka on 2026-07-24.
//

import Vision

public extension ContoursObservation.Contour {
    @backDeployed(before: macOS 26.0)
    var points: [ NormalizedPoint ] {
        self.normalizedPoints.map {
            .init(x: .init($0.x), y: .init($0.y))
        }
    }
}

public extension ContoursObservation.Contour {
    @backDeployed(before: macOS 26.0)
    var boundingBox: NormalizedRect {
        let points = self.points
        guard !points.isEmpty else {
            return .init(normalizedRect: .zero)
        }
        
        let (bottomLeft, topRight) = points[1...]
            .reduce(
                into: (bottomLeft: points[0].cgPoint, topRight: points[0].cgPoint)
            ) { partial, point in
                partial.bottomLeft.x = min(partial.bottomLeft.x, point.x)
                partial.bottomLeft.y = min(partial.bottomLeft.y, point.y)
                
                partial.topRight.x = max(partial.topRight.x, point.x)
                partial.topRight.y = max(partial.topRight.y, point.y)
            }
        
        return .init(
            x: bottomLeft.x,
            y: bottomLeft.y,
            width: topRight.x - bottomLeft.x,
            height: topRight.y - bottomLeft.y
        )
    }
}
