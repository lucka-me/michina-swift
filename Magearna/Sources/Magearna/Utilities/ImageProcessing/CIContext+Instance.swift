//
//  CIContext+Instance.swift
//  Magearna
//
//  Created by Lucka on 2026-05-23.
//

import CoreImage

extension CIContext {
    static let pipelineShared = CIContext(
        options: [
            .outputColorSpace : CGColorSpace(name: CGColorSpace.sRGB)!,
            .useSoftwareRenderer : false,
            .workingColorSpace: NSNull(),
        ]
    )
}
