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
        try boxes.map { box in
            let normalizedImage = try normalize(box: box, in: image)
            let data = try normalizedImage.decodeForONNX(
                gamma: StaticConfigurations.gamma,
                reverseChannels: true
            )
            
            let inputShape = StaticConfigurations.inputShape(width: normalizedImage.width)
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
            
            return try parse(outputs: outputs, minimalConfidence: minimalConfidence)
        }
    }
}

fileprivate extension RapidCharacterRecognition {
    enum StaticConfigurations {
        static let inputHeight: Int = 48
        static let rotateRatioThreshold = 1.5
        
        static let gamma = CGImage.Gamma.range(-1 ... 1)
        
        static let batchSize: NSNumber = 1
        static let channelCount: NSNumber = 3
        
        static func inputShape(width: Int) -> [ NSNumber ] {
            [
                batchSize,
                StaticConfigurations.channelCount,
                inputHeight as NSNumber,
                width as NSNumber,
            ]
        }
    }
}

fileprivate extension RapidCharacterRecognition {
    func normalize(box: Quadrilateral, in image: CIImage) throws -> CGImage {
        let height = box.height
        let width = box.width
        
        let anchor: CGPoint
        let rotation: CGFloat
        let scale: CGFloat
        let cropSize: CGSize
        
        if height / width < StaticConfigurations.rotateRatioThreshold {
            anchor = box.bottomLeft
            rotation = box.rotation
            scale = Double(StaticConfigurations.inputHeight) / height
            cropSize = .init(width: Int(width * scale), height: StaticConfigurations.inputHeight)
        } else {
            anchor = box.topLeft
            rotation = box.rotation + (.pi / 2)
            scale = Double(StaticConfigurations.inputHeight) / width
            cropSize = .init(width: Int(height * scale), height: StaticConfigurations.inputHeight)
        }
        
        let transformedImage = image
            .transformed(by: .identity
                .translatedBy(x: -anchor.x, y: -(image.extent.height - anchor.y))
                .concatenating(.identity.rotated(by: rotation))
                .concatenating(.identity.scaledBy(x: scale, y: scale))
            )
            .cropped(to: .init(origin: .zero, size: cropSize))
        
        guard
            let cgImage = CIContext.pipelineShared.createCGImage(
                transformedImage,
                from: .init(
                    origin: transformedImage.extent.origin,
                    size: cropSize
                )
            )
        else {
            throw .runtime("Unable to create CGImage")
        }
        return cgImage
    }
}

fileprivate extension RapidCharacterRecognition {
    func parse(
        outputs: [ String : ORTValue ],
        minimalConfidence: Float
    ) throws -> Output.Element {
        let value = outputs[session.outputNames[0]]!
        let shape = try value.tensorTypeAndShapeInfo().shape
        let flatValues = try value.array(of: Float.self)
        
        let lengthPerCharacter = shape[2].intValue
        
        let indices: [ Confident<Int> ] = stride(
            from: flatValues.startIndex,
            to: flatValues.endIndex,
            by: lengthPerCharacter
        )
        .map { characterStartIndex -> Confident<Int> in
            let element = flatValues[
                characterStartIndex ..< characterStartIndex + lengthPerCharacter
            ]
            .enumerated()
            .max { $0.element < $1.element }!
            
            return .init(
                confidence: element.element,
                item: element.offset
            )
        }
        .reduce(into: [ ]) { partial, character in
            guard
                let previous = partial.last,
                previous.item == character.item
            else {
                partial.append(character)
                return
            }
            guard previous.confidence < character.confidence else {
                return
            }
            partial[partial.endIndex - 1] = character
        }
        .filter {
            $0.item > 0
        }
        
        print(indices.map { sidecar.characters[$0.item] })
        
        let confidence = indices.reduce(Float.zero) { $0 + $1.confidence } / .init(indices.count)
        guard confidence >= minimalConfidence else {
            return nil
        }
        
        return .init(
            confidence: confidence,
            item: indices.reduce(into: "") {
                $0.append(sidecar.characters[$1.item])
            }
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
