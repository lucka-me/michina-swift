//
//  RetinaFace.swift
//  Magearna
//
//  Created by Lucka on 2026-05-21.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import ONNXRuntime

struct RetinaFace : FaceDetectionFunction {
    private let session: InferenceSession
    private let sidecar: Sidecar
    
    init(session: InferenceSession) {
        self.session = session
        guard case let .retinaFace(sidecar) = session.sidecar else {
            fatalError("The session doesn't contain RetinaFaceSidecar.")
        }
        self.sidecar = sidecar
    }
    
    func detect(image: CIImage, minimalConfidence: Float) throws -> Output {
        let (scaledImage, scale) = try scale(image: image)
        let data = try scaledImage.decodeForONNX(
            mean: StaticConfigurations.decodeMean,
            scale: StaticConfigurations.decodeScale
        )
        precondition(
            data.count == StaticConfigurations.inputShape.map(\.intValue).reduce(1, *) * MemoryLayout<Float>.size,
            "The length of input data doesn't match the input shape, check the processing."
        )
        
        let inputValue = try ORTValue(
            tensorData: .init(data: data),
            elementType: .float,
            shape: StaticConfigurations.inputShape
        )
        let outputs = try session.session.run(
            withInputs: [ session.inputNames[0] : inputValue ],
            outputNames: .init(session.outputNames),
            runOptions: nil
        )
        
        return try parse(outputs: outputs, minimalConfidence: minimalConfidence, scale: scale)
    }
}

fileprivate extension RetinaFace {
    enum StaticConfigurations {
        static let decodeMean: Float = 127.5
        static let decodeScale: Float = 1 / 128
        
        static let batchSize: NSNumber = 1
        static let channelCount: NSNumber = 3
        
        static let inputSize = CGSize(width: 640, height: 640)
        
        static let inputShape: [ NSNumber ] = [
            batchSize,
            channelCount,
            inputSize.height as NSNumber,
            inputSize.width as NSNumber,
        ]
        
        static let overlapThreshold = 0.4
    }
}

fileprivate extension RetinaFace {
    func scale(image: CIImage) throws -> (image: CGImage, scale: Double) {
        let imageSize = image.extent.size
        let scale: CGFloat
        let origin: CGPoint
        if imageSize.ratio > StaticConfigurations.inputSize.ratio {
            scale = StaticConfigurations.inputSize.width / imageSize.width
            // Core Graphics: Origin at Lower-Left
            // vImage and other: Origin at Upper-Left
            // So we need to move the origin down to keep the CGImage filled from top row
            // Both x grows right
            origin = .init(
                x: image.extent.origin.x,
                y: image.extent.origin.y - (StaticConfigurations.inputSize.height - imageSize.height * scale)
            )
        } else {
            scale = StaticConfigurations.inputSize.height / imageSize.height
            origin = image.extent.origin
        }
        
        let scaleFilter = CIFilter.lanczosScaleTransform()
        scaleFilter.inputImage = image
        scaleFilter.scale = .init(scale)
        scaleFilter.aspectRatio = 1
        guard let scaledImage = scaleFilter.outputImage else {
            throw .runtime("Unable to resize the image")
        }
        guard
            let cgImage = CIContext.pipelineShared.createCGImage(
                scaledImage,
                from: .init(origin: origin, size: StaticConfigurations.inputSize)
            )
        else {
            throw .runtime("Unable to create CGImage")
        }
        return (cgImage, scale)
    }
}

fileprivate extension RetinaFace {
    func parse(
        outputs: [ String : ORTValue ],
        minimalConfidence: Float,
        scale: Double
    ) throws -> Output {
        try sidecar.stridePerGroup
            .enumerated()
            .flatMap { groupIndex, groupStride -> Output in
                let confidences = try outputs[session.outputNames[groupIndex]]!
                    .array(of: Float.self)
                let filteredConfidences = confidences
                    .enumerated()
                    .filter { $0.element >= minimalConfidence }
                
                let boundingBoxesName = session
                    .outputNames[groupIndex + sidecar.groupsCount]
                let boundingBoxes = try outputs[boundingBoxesName]!
                    .array(of: SIMD4<Float>.self)
                
                let landmarks: [ SIMD2<Float> ]
                let landmarksPerFace: Int
                if sidecar.supportLandmarks {
                    let landmarksName = session
                        .outputNames[groupIndex + sidecar.groupsCount * 2]
                    let value = outputs[landmarksName]!
                    landmarks = try value.array(of: SIMD2<Float>.self)
                    
                    let info = try value.tensorTypeAndShapeInfo()
                    landmarksPerFace = info.shape[1].intValue / 2
                } else {
                    landmarks = [ ]
                    landmarksPerFace = 0
                }
                
                let groupWidth = Int(StaticConfigurations.inputSize.width / .init(groupStride))
                
                return filteredConfidences.map { (index, confidence) -> Output.Element in
                    let anchorIndex = index / sidecar.anchorsPerPoint
                    let anchorRow = Double((anchorIndex / groupWidth) * groupStride)
                    let anchorCol = Double((anchorIndex % groupWidth) * groupStride)
                    
                    let boundingBox = SIMD4<Double>(boundingBoxes[index]) * Double(groupStride)
                    
                    return .init(
                        confidence: confidence,
                        item: .init(
                            boundingBox: .init(
                                x: (anchorCol - boundingBox.x) / scale,
                                y: (anchorRow - boundingBox.y) / scale,
                                width: (boundingBox.x + boundingBox.z) / scale,
                                height: (boundingBox.y + boundingBox.w) / scale
                            ),
                            landmarks: landmarks[
                                index * landmarksPerFace ..< (index + 1) * landmarksPerFace
                            ].map {
                                .init(
                                    x: (anchorCol + Double($0.x) * Double(groupStride)) / scale,
                                    y: (anchorRow + Double($0.y) * Double(groupStride)) / scale
                                )
                            }
                        )
                    )
                }
            }
            .sorted(using: KeyPathComparator(\.confidence, order: .reverse))
            .reduce(into: [ ]) { partial, face in
                let faceArea = face.item.boundingBox.size.area
                let hasOverlap = partial.contains { otherFace in
                    guard
                        face.item.boundingBox.intersects(otherFace.item.boundingBox)
                    else {
                        return false
                    }
                    
                    let overlapArea = face.item.boundingBox
                        .intersection(otherFace.item.boundingBox)
                        .size.area
                    let totalArea = faceArea
                        + otherFace.item.boundingBox.size.area
                        - overlapArea
                    
                    return (overlapArea / totalArea) > StaticConfigurations.overlapThreshold
                }
                if !hasOverlap {
                    partial.append(face)
                }
            }
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
