//
//  RectangleGeometry.swift
//  Magearna
//
//  Created by Lucka on 2026-07-22.
//

import Foundation

public protocol RectangleRepresentable : QuadrilateralRepresentable {
    
}

public extension RectangleRepresentable {
    var height: Double {
        max(topLeft.distance(to: bottomLeft), topRight.distance(to: bottomRight))
    }
    
    var width: Double {
        max(topLeft.distance(to: topRight), bottomLeft.distance(to: bottomRight))
    }
}
    
public extension RectangleRepresentable {
    var ratio: Double {
        width / height
    }
    
    var area: Double {
        width * height
    }
    
    var perimeter: Double {
        (width + height) * 2
    }
}

public extension RectangleRepresentable {
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
