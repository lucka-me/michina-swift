//
//  CharacterRecognitionFunction.swift
//  Magearna
//
//  Created by Lucka on 2026-06-11.
//

import CoreImage

protocol CharacterRecognitionFunction : Sendable {
    typealias Rectangle = CharacterRecognitionInferencePipeline.Output.Rectangle
    typealias Output = [ Confident<String>? ]
    
    func recognize(
        rectangles: [ Rectangle ],
        in image: CIImage,
        minimalConfidence: Float
    ) async throws -> Output
}
