//
//  CharacterDetectionFunction.swift
//  Magearna
//
//  Created by Lucka on 2026-06-11.
//

import CoreImage

protocol CharacterDetectionFunction : Sendable {
    typealias Output = [ Confident<Quadrilateral> ]
    
    func detect(
        image: CIImage,
        minimalConfidence: Float,
        maximalResolution: Int
    ) async throws -> Output
}
