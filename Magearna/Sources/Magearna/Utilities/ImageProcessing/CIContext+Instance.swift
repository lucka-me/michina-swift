//
//  CIContext+Instance.swift
//  Magearna
//
//  Created by Lucka on 2026-05-23.
//

import CoreImage

extension CIContext {
    static let pipelineShared = CIContext(
        options: [ .useSoftwareRenderer : false ]
    )
}
