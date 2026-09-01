//
//  QuadrilateralRepresentable.swift
//  Magearna
//
//  Created by Lucka on 2026-06-02.
//

import Foundation

public protocol QuadrilateralRepresentable {
    associatedtype Point: PointRepresentable
    
    init(topLeft: Point, topRight: Point, bottomRight: Point, bottomLeft: Point)
    
    var topLeft: Point { get }
    var topRight: Point { get }
    var bottomRight: Point { get }
    var bottomLeft: Point { get }
}

public extension QuadrilateralRepresentable {
    var points: [ Point ] {
        [ topLeft, topRight, bottomRight, bottomLeft ]
    }
}

public extension QuadrilateralRepresentable {
    var boundingBox: CGRect {
        let allX = [ topLeft.x, topRight.x, bottomRight.x, bottomLeft.x ].sorted()
        let allY = [ topLeft.y, topRight.y, bottomRight.y, bottomLeft.y ].sorted()
        
        let minX = allX.first!
        let minY = allY.first!
        let maxX = allX.last!
        let maxY = allY.last!
        
        return .init(
            origin: .init(x: minX, y: minY),
            size: .init(width: maxX - minX, height: maxY - minY)
        )
    }
}
