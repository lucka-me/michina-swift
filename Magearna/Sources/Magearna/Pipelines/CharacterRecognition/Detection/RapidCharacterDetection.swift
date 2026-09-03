//
//  RapidCharacterDetection.swift
//  Magearna
//
//  Created by Lucka on 2026-05-31.
//

import Accelerate
import CoreImage
import ONNXRuntime
import VisionDeployment

struct RapidCharacterDetection : CharacterDetectionFunction {
    private let session: InferenceSession
    
    init(session: InferenceSession) {
        self.session = session
    }
    
    func detect(
        image: CIImage,
        minimalConfidence: Float,
        maximalResolution: Int
    ) async throws -> Output {
        guard
            .init(maximalResolution) >= StaticConfigurations.inputSizeBase,
            image.extent.size.width >= StaticConfigurations.inputSizeBase,
            image.extent.size.height >= StaticConfigurations.inputSizeBase
        else {
            return [ ]
        }
        
        let scaledImage = try scale(image: image, maximalResolution: maximalResolution)
        let data = try scaledImage.decodeForONNX(
            gamma: StaticConfigurations.gamma,
            reverseChannels: true
        )
        let inputShape = StaticConfigurations.inputShape(for: scaledImage)
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
        
        return try await parse(
            outputs: outputs,
            minimalConfidence: minimalConfidence,
            originalImageSize: image.extent.size
        )
    }
}

fileprivate extension RapidCharacterDetection {
    enum StaticConfigurations {
        static let inputSizeBase: CGFloat = 32
        
        static let gamma = CGImage.Gamma.openCV(scaleFactor: 1 / (0.5 * 255), mean: 0.5)
        
        static let batchSize: NSNumber = 1
        static let channelCount: NSNumber = 3
        
        static let expandRatio = 1.6
        
        static func inputShape(for image: CGImage) -> [ NSNumber ] {
            [
                batchSize,
                channelCount,
                image.height as NSNumber,
                image.width as NSNumber,
            ]
        }
        
        static func align(length: CGFloat) -> CGFloat {
            round(length / inputSizeBase) * inputSizeBase
        }
    }
}

fileprivate extension RapidCharacterDetection {
    func scale(image: CIImage, maximalResolution: Int) throws -> CGImage {
        let imageSize = image.extent.size
        let maxSize = StaticConfigurations.align(length: .init(maximalResolution))
        
        let scale: CGFloat
        let aspectRatio: CGFloat
        let scaledSize: CGSize
        
        // Immich uses maximalResolution as shorter edge
        if imageSize.width < imageSize.height {
            // Scale down only
            let resizedWidth = if imageSize.width < maxSize {
                StaticConfigurations.align(length: imageSize.width)
            } else {
                maxSize
            }
            
            let heightScale = resizedWidth / imageSize.width
            let resizedHeight = StaticConfigurations.align(
                length: imageSize.height * heightScale
            )
            scale = resizedHeight / imageSize.height
            aspectRatio = heightScale / scale
            scaledSize = .init(width: resizedWidth, height: resizedHeight)
        } else {
            let resizedHeight = if imageSize.height < maxSize {
                StaticConfigurations.align(length: imageSize.height)
            } else {
                maxSize
            }
            
            scale = resizedHeight / imageSize.height
            let resizedWidth = StaticConfigurations.align(length: imageSize.width * scale)
            aspectRatio = resizedWidth / imageSize.width / scale
            scaledSize = .init(width: resizedWidth, height: resizedHeight)
        }
        
        let scaleFilter = CIFilter.lanczosScaleTransform()
        scaleFilter.inputImage = image
        scaleFilter.scale = .init(scale)
        scaleFilter.aspectRatio = .init(aspectRatio)
        guard let scaledImage = scaleFilter.outputImage else {
            throw .runtime("Unable to resize the image")
        }
        guard
            let cgImage = CIContext.pipelineShared.createCGImage(
                scaledImage,
                from: .init(
                    origin: image.extent.origin,
                    size: scaledSize
                )
            )
        else {
            throw .runtime("Unable to create CGImage")
        }
        
        return cgImage
    }
}

fileprivate extension RapidCharacterDetection {
    func parse(
        outputs: [ String : ORTValue ],
        minimalConfidence: Float,
        originalImageSize: CGSize
    ) async throws -> Output {
        let confidencesValue = outputs[session.outputNames[0]]!
        let confidences = try confidencesValue.array(of: Float.self)
        guard confidences.contains(where: { $0 > minimalConfidence}) else {
            return [ ]
        }
        
        let confidencesShape = try confidencesValue.tensorTypeAndShapeInfo().shape
        let bufferSize = vImage.Size(
            width: confidencesShape[3].intValue,
            height: confidencesShape[2].intValue
        )
        
        let pixelFormat = vImage.PlanarF.self
        let binaryBuffer = vImage.PixelBuffer(
            pixelValues: confidences,
            size: bufferSize,
            pixelFormat: pixelFormat
        )
        binaryBuffer.colorThreshold(minimalConfidence, destination: binaryBuffer)
        
        let dilatedBuffer = vImage.PixelBuffer(size: bufferSize, pixelFormat: pixelFormat)
        binaryBuffer.applyMorphology(
            operation: .dilate(
                structuringElement: .init(
                    values: .init(repeating: 1, count: 3 * 3),
                    width: 3,
                    height: 3
                )
            ),
            destination: dilatedBuffer
        )
        
        let contours = try await ContoursVision.detect(in: dilatedBuffer)
        let bufferImageSize = CGSize(width: bufferSize.width, height: bufferSize.height)
        
        return contours.map { contour in
            // Iterate every pixel in the bounding box, check if it's inside the contour, then accumulate
            let boundingBox = contour.boundingBox(in: bufferImageSize)
            
            let rowRange = Int(boundingBox.minY) ..< Int(boundingBox.maxY)
            let colRange = Int(boundingBox.minX) ..< Int(boundingBox.maxX)
            let accumulated: (count: Int, confidence: Double) = rowRange.reduce(
                into: (0, 0.0)
            ) { accumulated, row in
                accumulated = colRange.reduce(into: accumulated) { accumulated, col in
                    let point = CGPoint(
                        x: .init(col) / bufferImageSize.width,
                        y: .init(row) / bufferImageSize.height
                    )
                    guard contour.contains(normalizedPoint: point) else {
                        return
                    }
                    accumulated.count += 1
                    accumulated.confidence += .init(
                        confidences[row * bufferSize.width + col]
                    )
                }
            }
            
            return .init(
                confidence: .init(accumulated.confidence / .init(accumulated.count)),
                item: contour.minimalBounding(
                    in: originalImageSize,
                    expandBy: StaticConfigurations.expandRatio
                )
            )
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
