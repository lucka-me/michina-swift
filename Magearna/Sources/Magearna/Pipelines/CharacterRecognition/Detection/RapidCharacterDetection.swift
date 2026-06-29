//
//  RapidCharacterDetection.swift
//  Magearna
//
//  Created by Lucka on 2026-05-31.
//

import Accelerate
import CoreImage
import ONNXRuntime
import Vision

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
            mean: StaticConfigurations.decodeMean,
            scale: StaticConfigurations.decodeScale
        )
        let inputShape = StaticConfigurations.inputShape(for: scaledImage)
        precondition(
            data.count == inputShape.map(\.intValue).reduce(1, *) * MemoryLayout<Float>.size,
            "The length of input data doesn't match the input shape, check the processing."
        )
        
        let inputValue = try ORTValue(
            tensorData: .init(data: data),
            elementType: .float,
            shape: [
                StaticConfigurations.batchSize,
                StaticConfigurations.channelCount,
                scaledImage.height as NSNumber,
                scaledImage.width as NSNumber,
            ]
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
        
        static let decodeMean: Float = 0.5
        static let decodeScale: Float = 1 / (0.5 * 255)
        
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
    }
}

fileprivate extension RapidCharacterDetection {
    func scale(image: CIImage, maximalResolution: Int) throws -> CGImage {
        let imageSize = image.extent.size
        let maxSize = floor(
            .init(maximalResolution) / StaticConfigurations.inputSizeBase
        ) * StaticConfigurations.inputSizeBase
        
        let scale: CGFloat
        let aspectRatio: CGFloat
        let scaledSize: CGSize
        
        if imageSize.width > imageSize.height {
            let heightScale = maxSize / imageSize.width
            let resizedHeight = floor(
                imageSize.height * heightScale / StaticConfigurations.inputSizeBase
            ) * StaticConfigurations.inputSizeBase
            scale = resizedHeight / imageSize.height
            aspectRatio = heightScale / scale
            scaledSize = .init(width: Int(maxSize), height: Int(resizedHeight))
        } else {
            scale = maxSize / imageSize.height
            let resizedWidth = floor(
                imageSize.width * scale / StaticConfigurations.inputSizeBase
            ) * StaticConfigurations.inputSizeBase
            aspectRatio = resizedWidth / imageSize.width / scale
            scaledSize = .init(width: Int(resizedWidth), height: Int(maxSize))
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
        
        let confideShncesape = try confidencesValue.tensorTypeAndShapeInfo().shape
        let bufferSize = vImage.Size(
            width: confideShncesape[3].intValue,
            height: confideShncesape[2].intValue
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
        guard
            let cgImage = dilatedBuffer.makeCGImage(
                cgImageFormat: .init(
                    bitsPerComponent: 32,
                    bitsPerPixel: 32,
                    colorSpace: .init(name: CGColorSpace.linearGray)!,
                    bitmapInfo: .init(
                        alpha: .none,
                        component: .float,
                        byteOrder: .order32Host
                    )
                )!
            )
        else {
            throw .runtime("Unable to create binary CGImage.")
        }
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        let handler = ImageRequestHandler(cgImage)
        var request = DetectContoursRequest()
        request.detectsDarkOnLight = false
        let contours = try await handler.perform(request)
        return contours.topLevelContours.map { contour in
            // Iterate every pixel in the bounding box, check if it's inside the contour, then accumulate
            let path = contour.normalizedPath
            
            let boundingBox = contour.boundingBox
                .verticallyFlipped()
                .toImageCoordinates(imageSize)
            let rowRange = (Int(boundingBox.minY) ..< Int(boundingBox.maxY))
            let colRange = (Int(boundingBox.minX) ..< Int(boundingBox.maxX))
            let accumulated: (count: Int, confidence: Double) = rowRange.reduce(
                into: (0, 0.0)
            ) { accumulated, row in
                accumulated = colRange.reduce(into: accumulated) { accumulated, col in
                    let point = CGPoint(
                        x: .init(col) / imageSize.width,
                        y: 1.0 - .init(row) / imageSize.height
                    )
                    guard path.contains(point) else {
                        return
                    }
                    accumulated.count += 1
                    accumulated.confidence += .init(
                        confidences[row * bufferSize.width + col]
                    )
                }
            }
            
            let boundingRectangle = contour.minimalBoundingRectangle()
            let quadrilateral = Quadrilateral(
                topLeft: boundingRectangle.topLeft
                    .verticallyFlipped()
                    .toImageCoordinates(originalImageSize),
                topRight: boundingRectangle.topRight
                    .verticallyFlipped()
                    .toImageCoordinates(originalImageSize),
                bottomRight: boundingRectangle.bottomRight
                    .verticallyFlipped()
                    .toImageCoordinates(originalImageSize),
                bottomLeft: boundingRectangle.bottomLeft
                    .verticallyFlipped()
                    .toImageCoordinates(originalImageSize)
            )
            
            return .init(
                confidence: .init(accumulated.confidence / .init(accumulated.count)),
                item: quadrilateral.expand(by: StaticConfigurations.expandRatio)
            )
        }
    }
}

fileprivate extension Quadrilateral {
    func expand(by ratio: Double) -> Self {
        let distance = self.area * ratio / self.perimeter
        return .init(
            topLeft: topLeft.extend(a: bottomLeft, b: topRight, by: distance),
            topRight: topRight.extend(a: topLeft, b: bottomRight, by: distance),
            bottomRight: bottomRight.extend(a: topRight, b: bottomLeft, by: distance),
            bottomLeft: bottomLeft.extend(a: bottomRight, b: topLeft, by: distance)
        )
    }
}

fileprivate extension CGPoint {
    func extend(a: Self, b: Self, by distance: Double) -> Self {
        let dx1 = self.x - a.x
        let dy1 = self.y - a.y
        
        let a1: Double, b1: Double, c1: Double
        if dx1.isZero {
            a1 = 1
            b1 = 0
            c1 = dy1 > 0 ? -distance : distance
        } else if dy1.isZero {
            a1 = 0
            b1 = 1
            c1 = dx1 > 0 ? distance : -distance
        } else {
            a1 = dy1
            b1 = -dx1
            c1 = -distance * hypot(dx1, dy1)
        }
        
        let dx2 = b.x - self.x
        let dy2 = b.y - self.y
        
        let a2: Double, b2: Double, c2: Double
        if dx2.isZero {
            a2 = 1
            b2 = 0
            c2 = dy2 > 0 ? -distance : distance
        } else if dy2.isZero {
            a2 = 0
            b2 = 1
            c2 = dx2 > 0 ? distance : -distance
        } else {
            a2 = dy2
            b2 = -dx2
            c2 = -distance * hypot(dx2, dy2)
        }
        
        let x = (b1 * c2 - b2 * c1) / (a1 * b2 - a2 * b1)
        let y = (a2 * c1 - a1 * c2) / (a1 * b2 - a2 * b1)
        
        return .init(
            x: self.x + x,
            y: self.y + y
        )
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
