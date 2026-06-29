//
//  QuadrilateralShape.swift
//  Magearna
//
//  Created by Lucka on 2026-06-02.
//

import Foundation
import Vision

public protocol QuadrilateralShape {
    associatedtype Point: PointShape
    
    var topLeft: Point { get }
    var topRight: Point { get }
    var bottomRight: Point { get }
    var bottomLeft: Point { get }
}

public extension QuadrilateralShape {
    var points: [ Point ] {
        [ topLeft, topRight, bottomRight, bottomLeft ]
    }
}

public extension QuadrilateralShape {
    var height: Double {
        max(topLeft.distance(to: bottomLeft), topRight.distance(to: bottomRight))
    }
    
    var width: Double {
        max(topLeft.distance(to: topRight), bottomLeft.distance(to: bottomRight))
    }
    
    var ratio: Double {
        width / height
    }
}

extension QuadrilateralShape {
    var area: Double {
        let sides = [
            topLeft.distance(to: topRight),
            topRight.distance(to: bottomRight),
            bottomRight.distance(to: bottomLeft),
            bottomLeft.distance(to: topLeft),
        ]
        let crossLength = topLeft.distance(to: bottomRight)
        let s1 = (sides[0] + sides[1] + crossLength) / 2
        let s2 = (sides[2] + sides[3] + crossLength) / 2
        return sqrt(s1 * (s1 - sides[0]) * (s1 - sides[1]) * (s1 - crossLength))
            + sqrt(s2 * (s2 - sides[2]) * (s2 - sides[3]) * (s2 - crossLength))
    }
    
    var perimeter: Double {
        topLeft.distance(to: topRight)
        + topRight.distance(to: bottomRight)
        + bottomRight.distance(to: bottomLeft)
        + bottomLeft.distance(to: topLeft)
    }
}

extension RectangleObservation : QuadrilateralShape {
    
}
