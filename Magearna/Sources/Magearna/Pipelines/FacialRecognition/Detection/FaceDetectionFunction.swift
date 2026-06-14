//
//  FaceDetectionFunction.swift
//  Magearna
//
//  Created by Lucka on 2026-05-29.
//

import CoreImage

protocol FaceDetectionFunction : Sendable {
    typealias FaceGeometry = FacialRecognitionInferencePipeline.Output.FaceGeometry
    typealias Output = [ Confident<FaceGeometry> ]
    
    func detect(image: CIImage, minimalConfidence: Float) async throws -> Output
}
