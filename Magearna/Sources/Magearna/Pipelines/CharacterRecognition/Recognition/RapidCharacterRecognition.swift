//
//  RapidCharacterRecognition.swift
//  Magearna
//
//  Created by Lucka on 2026-05-31.
//

import CoreImage
import ONNXRuntime

struct RapidCharacterRecognition : CharacterRecognitionFunction {
    private let session: InferenceSession
    private let sidecar: Sidecar
    
    init(session: InferenceSession) {
        self.session = session
        guard
            case let .rapidCharacterRecognition(sidecar) = session.sidecar
        else {
            fatalError("The session doesn't contain RapidCharacterRecognitionSidecar.")
        }
        self.sidecar = sidecar
    }
    
    func recognize(
        boxes: [ Quadrilateral ],
        in image: CIImage,
        minimalConfidence: Float
    ) throws -> Output {
        let data = try boxes
            .map { try normalize(box: $0, in: image) }
            .map {
                try $0.decodeForONNX(
                    mean: StaticConfigurations.decodeMean,
                    scale: StaticConfigurations.decodeScale
                )
            }
            .reduce(into: Data()) { partial, data in
                partial.append(data)
            }
        let inputShape = StaticConfigurations.inputShape(batchSize: boxes.count)
        precondition(
            data.count == inputShape.map(\.intValue).reduce(1, *) * MemoryLayout<Float>.size,
            "The length of input data doesn't match the input shape, check the processing."
        )
        
        let inputValue = try ORTValue(
            tensorData: .init(data: data),
            elementType: .float,
            shape: [
                boxes.count as NSNumber,
                StaticConfigurations.channelCount,
                StaticConfigurations.inputSize.height as NSNumber,
                StaticConfigurations.inputSize.width as NSNumber,
            ]
        )
        let outputs = try session.session.run(
            withInputs: [ session.inputNames[0] : inputValue ],
            outputNames: .init(session.outputNames),
            runOptions: nil
        )
        
        return try parse(outputs: outputs, minimalConfidence: minimalConfidence)
    }
}

fileprivate extension RapidCharacterRecognition {
    enum StaticConfigurations {
        static let inputSize = CGSize(width: 320, height: 48)
        
        static let decodeMean: Float = 127.5
        static let decodeScale: Float = 1 / 127.5
        
        static let channelCount: NSNumber = 3
        
        static func inputShape(batchSize: Int) -> [ NSNumber ] {
            [
                batchSize as NSNumber,
                StaticConfigurations.channelCount,
                StaticConfigurations.inputSize.height as NSNumber,
                StaticConfigurations.inputSize.width as NSNumber,
            ]
        }
    }
}

fileprivate extension RapidCharacterRecognition {
    func normalize(box: Quadrilateral, in image: CIImage) throws -> CGImage {
        let boundingBox = box.boundingBox
        let height = box.height
        let width = box.width
        
        let destinationRect: CGRect = .init(
            origin: boundingBox.origin,
            size: StaticConfigurations.inputSize
        )
        
        let source: [ CGPoint ]
        let destinationRight: CGFloat
        let destinationBottom: CGFloat
        
        if width > height {
            source = box.points
            
            if width / height > StaticConfigurations.inputSize.ratio {
                destinationRight = destinationRect.maxX
                destinationBottom = destinationRect.minY
                    + height * StaticConfigurations.inputSize.width / width
            } else {
                destinationRight = destinationRect.minX
                    + width * StaticConfigurations.inputSize.height / height
                destinationBottom = destinationRect.maxY
            }
        } else {
            // Rotate 90 degree
            source = [ box.topRight, box.bottomRight, box.bottomLeft, box.topLeft ]
            
            if height / width > StaticConfigurations.inputSize.ratio {
                destinationRight = destinationRect.maxX
                destinationBottom = destinationRect.minY
                    + width * StaticConfigurations.inputSize.height / width
            } else {
                destinationRight = destinationRect.minX
                    + height * StaticConfigurations.inputSize.width / height
                destinationBottom = destinationRect.maxY
            }
        }
        
        let destinationLeft = destinationRect.origin.x
        let destinationTop = destinationRect.origin.y
        let destination: [ CGPoint ] = [
            .init(x: destinationLeft, y: destinationTop),
            .init(x: destinationRight, y: destinationTop),
            .init(x: destinationRight, y: destinationBottom),
            .init(x: destinationLeft, y: destinationBottom),
        ]
        let transformedImage = image.transformed(
            by: .similarityTransform(
                from: source.map { $0.verticallyFlipped(in: image.extent.size) },
                to: destination.map { $0.verticallyFlipped(in: image.extent.size) }
            )
        )
        
        guard
            let cgImage = CIContext.pipelineShared.createCGImage(
                transformedImage,
                from: destinationRect.verticallyFlipped(in: image.extent.size)
            )
        else {
            throw .runtime("Unable to create CGImage")
        }
        return cgImage
    }
}

fileprivate extension RapidCharacterRecognition {
    func parse(outputs: [ String : ORTValue ], minimalConfidence: Float) throws -> Output {
        let value = outputs[session.outputNames[0]]!
        let shape = try value.tensorTypeAndShapeInfo().shape
        let flatValues = try value.array(of: Float.self)
        
        let lengthPerItem = flatValues.count / shape[0].intValue
        let tokensPerItem = shape[1].intValue
        let lengthPerToken = shape[2].intValue
        
        return stride(from: flatValues.startIndex, to: flatValues.endIndex, by: lengthPerItem)
            .map { itemIndex in
                let itemSlice = flatValues[itemIndex ..< itemIndex + lengthPerItem]
                let (text, accumulatedConfidence) = stride(
                    from: itemSlice.startIndex,
                    to: itemSlice.endIndex,
                    by: lengthPerToken
                )
                .map { tokenIndex -> (character: String, confidence: Float) in
                    let element = itemSlice[tokenIndex ..< tokenIndex + lengthPerToken]
                        .enumerated()
                        .max { $0.element < $1.element }!
                    return (
                        character: sidecar.characters[element.offset],
                        confidence: element.element
                    )
                }
                .reduce(into: (text: "", confidence: Float.zero)) { partial, token in
                    guard !partial.text.hasSuffix(token.character) else {
                        // Duplicated
                        return
                    }
                    partial.text.append(token.character)
                    partial.confidence += token.confidence
                }
                
                guard !text.isEmpty else {
                    return nil
                }
                
                let confidence = accumulatedConfidence / .init(text.count)
                guard confidence >= minimalConfidence else {
                    return nil
                }
                return .init(confidence: confidence, item: text)
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
