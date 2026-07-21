//
//  QuadrilateralShape.swift
//  Magearna
//
//  Created by Lucka on 2026-06-02.
//

import Foundation

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
    
    var rotation: Double {
        let dx = self.topRight.x - self.topLeft.x
        let dy = self.topRight.y - self.topLeft.y
        
        return if dy.isZero {
            .zero
        } else if dx.isZero {
            .pi / 2
        } else {
            atan2(dy, dx)
        }
    }
}

extension QuadrilateralShape {
    var area: Double {
        width * height
    }
    
    var perimeter: Double {
        (width + height) * 2
    }
}
