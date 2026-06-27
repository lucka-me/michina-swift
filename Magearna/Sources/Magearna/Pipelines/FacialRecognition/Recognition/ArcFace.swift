//
//  ArcFace.swift
//  Magearna
//
//  Created by Lucka on 2026-05-21.
//

import CoreImage
import ONNXRuntime
import SwiftProtobuf

struct ArcFace : Sendable {
    private let session: InferenceSession
    private let sidecar: Sidecar
    
    init(session: InferenceSession) {
        self.session = session
        guard
            case let .arcFace(sidecar) = session.sidecar
        else {
            fatalError("The session doesn't contain ArcFaceSidecar.")
        }
        self.sidecar = sidecar
    }
}

extension ArcFace {
    typealias FaceGeometry = FacialRecognitionInferencePipeline.Output.FaceGeometry
    typealias Output = [ Embedding ]
    
    func identify(faces: [ FaceGeometry ], in image: CIImage) throws -> Output {
        // TODO: Convert to task group
        let dataBatch = try faces
            .map { try normalize(face: $0, in: image) }
            .map {
                try $0.decodeForONNX(
                    mean: sidecar.decodeMean,
                    scale: sidecar.decodeScale
                )
            }
        
        return if sidecar.supportsBatch || faces.count == 1 {
            try run(
                data: dataBatch.reduce(into: .init()) { $0.append($1) },
                batchSize: faces.count
            )
        } else {
            try dataBatch.map {
                try run(data: $0, batchSize: 1)[0]
            }
        }
    }
}

fileprivate extension ArcFace {
    enum StaticConfigurations {
        static let channelCount: NSNumber = 3
        
        static let inputSize = CGSize(width: 112, height: 112)
        
        static let normalizedLandmarks: [ CGPoint ] = [
            CGPoint(x: 38.2946, y: 51.6963), CGPoint(x: 73.5318, y: 51.5014),
            CGPoint(x: 56.0252, y: 71.7366),
            CGPoint(x: 41.5493, y: 92.3655), CGPoint(x: 70.7299, y: 92.2041)
        ].map { $0.verticallyFlipped(in: inputSize) }
        
        static func inputShape(batchSize: Int) -> [ NSNumber ] {
            [
                batchSize as NSNumber,
                StaticConfigurations.channelCount,
                StaticConfigurations.inputSize.width as NSNumber,
                StaticConfigurations.inputSize.height as NSNumber,
            ]
        }
    }
}

fileprivate extension ArcFace {
    func normalize(face: FaceGeometry, in image: CIImage) throws -> CGImage {
        let transformedImage: CIImage
        if face.landmarks.count == StaticConfigurations.normalizedLandmarks.count {
            transformedImage = image.transformed(
                by: .similarityTransform(
                    from: face.landmarks.map { $0.verticallyFlipped(in: image.extent.size) },
                    to: StaticConfigurations.normalizedLandmarks
                )
            )
        } else {
            // TODO: Check if the transform anchor is (0, 0)
            transformedImage = image.transformed(
                by: .identity
                    .translatedBy(
                        x: -face.boundingBox.minX,
                        y: -(image.extent.height - face.boundingBox.maxY)
                    )
                    .scaledBy(
                        x: StaticConfigurations.inputSize.width / face.boundingBox.width,
                        y: StaticConfigurations.inputSize.height / face.boundingBox.height
                    )
            )
        }
        
        guard
            let cgImage = CIContext.pipelineShared.createCGImage(
                transformedImage,
                from: .init(
                    origin: image.extent.origin,
                    size: StaticConfigurations.inputSize
                )
            )
        else {
            throw .runtime("Unable to create CGImage")
        }
        return cgImage
    }
}

fileprivate extension ArcFace {
    func run(data: Data, batchSize: Int) throws -> Output {
        let inputShape = StaticConfigurations.inputShape(batchSize: batchSize)
        precondition(
            data.count == inputShape.map(\.intValue).reduce(1, *) * MemoryLayout<Float>.size,
            "The length of input data doesn't match the input shape, check the processing."
        )
        let inputValue = try ORTValue(
            tensorData: .init(data: data),
            elementType: .float,
            shape: inputShape
        )
        
        let outputs = try session.session.run(
            withInputs: [ session.inputNames[0] : inputValue ],
            outputNames: .init(session.outputNames),
            runOptions: nil
        )
        return try parse(outputs: outputs)
    }
}

fileprivate extension ArcFace {
    func parse(outputs: [ String : ORTValue ]) throws -> Output {
        let value = outputs[session.outputNames[0]]!
        let shape = try value.tensorTypeAndShapeInfo().shape
        let flatEmbeddings = try value.array(of: Float.self)
        let lengthPerItem = shape[1].intValue
        return stride(from: 0, to: flatEmbeddings.count, by: lengthPerItem)
            .map { .init(flatEmbeddings[$0 ..< $0 + lengthPerItem]) }
    }
}

fileprivate struct RuntimeError : Error {
    let reason: String
    
    var localizedDescription: String {
        reason
    }
}

fileprivate extension Error where Self == RuntimeError {
    static func runtime(_ reason: String) -> RuntimeError {
        .init(reason: reason)
    }
}

fileprivate extension Array where Element == SIMD2<Double> {
    var mean: Element {
        let sum = reduce(Element.zero, +)
        return sum / Double(count)
    }
}
