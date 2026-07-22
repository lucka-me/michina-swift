//
//  PointRepresentable.swift
//  Magearna
//
//  Created by Lucka on 2026-06-02.
//

import Foundation
import Vision

public protocol PointRepresentable {
    init(x: CGFloat, y: CGFloat)
    
    var x: CGFloat { get }
    var y: CGFloat { get }
}

extension PointRepresentable {
    func distance(to other: Self) -> Double {
        hypot(other.x - self.x, other.y - self.y)
    }
}

extension CGPoint : PointRepresentable {
    
}

extension NormalizedPoint : PointRepresentable {
    
}
