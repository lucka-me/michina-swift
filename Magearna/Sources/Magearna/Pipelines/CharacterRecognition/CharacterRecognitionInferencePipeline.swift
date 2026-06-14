//
//  CharacterRecognitionInferencePipeline.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

import CoreImage
import ONNXRuntime

public actor CharacterRecognitionInferencePipeline : InferencePipeline {
    public static let category = InferenceModelSuite.Category.characterRecognition
    
    public private(set) var modelReports: [InferencePipelineModelReport] = [ ]
    
    private let input: Input
    
    private var detection: CharacterDetectionFunction? = nil
    private var recognition: CharacterRecognitionFunction? = nil
    
    private var detectionOutputs: RapidCharacterDetection.Output = [ ]
    private var recognitionOutputs: RapidCharacterRecognition.Output = [ ]
    
    public init(_ input: Input) {
        self.input = input
    }
    
    public var models: [ InferenceModel ] {
        [ self.detectionModel, input.recognitionModel ]
    }
    
    public func prepare(_ sessions: [ InferenceModel.Category : InferenceSession ]) throws {
        self.detectionOutputs.removeAll()
        self.recognitionOutputs.removeAll()
        
        guard input.recognitionModel.provider != .apple else {
            let analyzer = AppleVisionCharacterAnalyzer()
            self.detection = analyzer
            self.recognition = analyzer
            return
        }
        
        switch input.detectionModel.provider {
        case .immichApp, .rapidOCR:
            guard let detectionSession = sessions[.detection] else {
                fatalError(
                    "Unable to extract session for detection required by " +
                    "CharacterRecognitionInferencePipeline."
                )
            }
            self.detection = RapidCharacterDetection(session: detectionSession)
        case .apple:
            self.detection = AppleVisionCharacterDetectionAnalyzer()
        }
        
        guard let recognitionSession = sessions[.recognition] else {
            fatalError(
                "Unable to extract session for recognition required by " +
                "CharacterRecognitionInferencePipeline."
            )
        }
        self.recognition = RapidCharacterRecognition(session: recognitionSession)
    }
    
    public func run() async throws -> Output {
        guard let detection, let recognition else {
            fatalError("CharacterRecognitionInferencePipeline.prepared() was not called.")
        }
        
        let image = input.image
        let clock = ContinuousClock()
        
        let detectionElapse = try await clock.measure {
            detectionOutputs = try await detection.detect(
                image: image,
                minimalConfidence: input.detectionMinimalConfidence,
                maximalResolution: input.detectionMaximalResolution
            )
        }
        self.modelReports.append(
            .init(model: self.detectionModel, elapse: detectionElapse)
        )
        guard !detectionOutputs.isEmpty else {
            return .init(characterBoxes: [ ])
        }
        
        let recognitionElapse = try await clock.measure {
            recognitionOutputs = try await recognition.recognize(
                boxes: detectionOutputs.map(\.item),
                in: image,
                minimalConfidence: input.recognitionMinimalConfidence
            )
        }
        self.modelReports.append(
            .init(model: input.recognitionModel, elapse: recognitionElapse)
        )
        
        return .init(
            characterBoxes: zip(detectionOutputs, recognitionOutputs)
                .compactMap { box, text in
                    if let text {
                        .init(text: text, shape: box)
                    } else {
                        nil
                    }
                }
        )
    }
}

public extension CharacterRecognitionInferencePipeline {
    struct Input : Sendable {
        let detectionModel: InferenceModel
        let detectionMinimalConfidence: Float
        let detectionMaximalResolution: Int
        
        let recognitionModel: InferenceModel
        let recognitionMinimalConfidence: Float
        
        public let image: CIImage
        
        public init(
            detectionModel: InferenceModel,
            detectionMinimalConfidence: Float,
            detectionMaximalResolution: Int,
            recognitionModel: InferenceModel,
            recognitionMinimalConfidence: Float,
            image: CIImage
        ) {
            self.detectionModel = detectionModel
            self.detectionMinimalConfidence = detectionMinimalConfidence
            self.detectionMaximalResolution = detectionMaximalResolution
            self.recognitionModel = recognitionModel
            self.recognitionMinimalConfidence = recognitionMinimalConfidence
            self.image = image
        }
    }
    
    struct Output : Sendable {
        public struct CharacterBox : Sendable {
            public let text: Confident<String>
            public let shape: Confident<Quadrilateral>
        }
        
        public let characterBoxes: [ CharacterBox ]
    }
}

fileprivate extension CharacterRecognitionInferencePipeline {
    var detectionModel: InferenceModel {
        switch input.recognitionModel.provider {
        case .apple: .find(
            suiteCategory: .characterRecognition,
            suiteName: input.recognitionModel.suiteName,
            modelCategory: .detection
        )!
        default: input.detectionModel
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
