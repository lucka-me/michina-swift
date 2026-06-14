//
//  Quadrilateral.swift
//  Magearna
//
//  Created by Lucka on 2026-06-02.
//

import Foundation

public struct Quadrilateral : Sendable, QuadrilateralShape {
    public let topLeft: CGPoint
    public let topRight: CGPoint
    public let bottomRight: CGPoint
    public let bottomLeft: CGPoint
}

public extension Quadrilateral {
    var boundingBox: CGRect {
        let allX = [ topLeft.x, topRight.x, bottomRight.x, bottomLeft.x ]
        let allY = [ topLeft.y, topRight.y, bottomRight.y, bottomLeft.y ]
        
        let minX = allX.min()!
        let minY = allY.min()!
        let maxX = allX.max()!
        let maxY = allY.max()!
        
        return .init(
            origin: .init(x: minX, y: minY),
            size: .init(width: maxX - minX, height: maxY - minY)
        )
    }
}
