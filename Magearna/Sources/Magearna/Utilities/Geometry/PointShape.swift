//
//  PointShape.swift
//  Magearna
//
//  Created by Lucka on 2026-06-02.
//

import Foundation
import Vision

public protocol PointShape {
    init(x: CGFloat, y: CGFloat)
    
    var x: CGFloat { get }
    var y: CGFloat { get }
}

extension PointShape {
    func distance(to other: Self) -> Double {
        hypot(other.x - self.x, other.y - self.y)
    }
}

extension CGPoint : PointShape {
    
}

extension NormalizedPoint : PointShape {
    
}
