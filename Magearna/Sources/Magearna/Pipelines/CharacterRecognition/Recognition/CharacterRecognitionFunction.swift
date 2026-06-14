//
//  CharacterRecognitionFunction.swift
//  Magearna
//
//  Created by Lucka on 2026-06-11.
//

import CoreImage

protocol CharacterRecognitionFunction : Sendable {
    typealias Output = [ Confident<String>? ]
    
    func recognize(
        boxes: [ Quadrilateral ],
        in image: CIImage,
        minimalConfidence: Float
    ) async throws -> Output
}
