//
//  CGGeometry+VerticalFlipped.swift
//  Magearna
//
//  Created by Lucka on 2026-06-02.
//

import Foundation

extension CGPoint {
    func verticallyFlipped(in extent: CGSize) -> Self {
        .init(
            x: self.x, y: extent.height - self.y
        )
    }
}

extension CGRect {
    func verticallyFlipped(in extent: CGSize) -> Self {
        .init(
            origin: .init(
                x: self.origin.x,
                y: extent.height - self.origin.y - self.size.height
            ),
            size: self.size
        )
    }
}
