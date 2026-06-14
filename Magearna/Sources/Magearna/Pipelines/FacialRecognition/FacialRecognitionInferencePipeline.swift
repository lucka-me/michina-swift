//
//  FacialRecognitionInferencePipeline.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

import CoreImage

public actor FacialRecognitionInferencePipeline : InferencePipeline {
    public static let category = InferenceModelSuite.Category.facialRecognition
    
    public private(set) var modelReports: [InferencePipelineModelReport] = [ ]
    
    private let input: Input
    
    private var detection: FaceDetectionFunction? = nil
    private var arcFace: ArcFace? = nil
    
    private var detectionOutputs: FaceDetectionFunction.Output = [ ]
    private var recognitionOutputs: ArcFace.Output = [ ]
    
    public init(_ input: Input) {
        self.input = input
    }
    
    public var models: [ InferenceModel ] {
        [ input.detectionModel, input.recognitionModel ]
    }
    
    public func prepare(_ sessions: [ InferenceModel.Category : InferenceSession ]) throws {
        switch input.detectionModel.provider {
        case .immichApp, .rapidOCR:
            guard let detectionSession = sessions[.detection] else {
                fatalError(
                    "Unable to extract session for detection required by FacialRecognitionInferencePipeline."
                )
            }
            self.detection = RetinaFace(session: detectionSession)
        case .apple:
            self.detection = AppleVisionFacialAnalyzer()
        }
        
        guard let recognitionSession = sessions[.recognition] else {
            fatalError(
                "Unable to extract session for recognition required by FacialRecognitionInferencePipeline."
            )
        }
        self.arcFace = ArcFace(session: recognitionSession)
        
        self.detectionOutputs.removeAll()
        self.recognitionOutputs.removeAll()
    }
    
    public func run() async throws -> Output {
        guard let detection, let arcFace else {
            fatalError("FacialRecognitionInferencePipeline.prepared() was not called.")
        }
        
        let image = input.image
        let clock = ContinuousClock()
        
        let detectionElapse = try await clock.measure {
            detectionOutputs = try await detection.detect(
                image: image,
                minimalConfidence: input.detectionMinimalConfidence
            )
        }
        self.modelReports.append(
            .init(model: input.detectionModel, elapse: detectionElapse)
        )
        guard !detectionOutputs.isEmpty else {
            return .empty
        }
        
        let recognitionElapse = try clock.measure {
            recognitionOutputs = try arcFace.identify(
                faces: detectionOutputs.map(\.item),
                in: image
            )
        }
        self.modelReports.append(
            .init(model: input.recognitionModel, elapse: recognitionElapse)
        )
        
        return .init(
            faces: zip(detectionOutputs, recognitionOutputs).map {
                .init(geometry: $0, embedding: $1)
            }
        )
    }
}

public extension FacialRecognitionInferencePipeline {
    struct Input : Sendable {
        let detectionModel: InferenceModel
        let detectionMinimalConfidence: Float
        
        let recognitionModel: InferenceModel
        
        public let image: CIImage
        
        public init(
            detectionModel: InferenceModel,
            detectionMinimalConfidence: Float,
            recognitionModel: InferenceModel,
            image: CIImage
        ) {
            self.detectionModel = detectionModel
            self.detectionMinimalConfidence = detectionMinimalConfidence
            self.recognitionModel = recognitionModel
            self.image = image
        }
    }
    
    struct Output : Sendable {
        public struct Face : Sendable {
            public let geometry: Confident<FaceGeometry>
            public let embedding: Embedding
        }
        
        public struct FaceGeometry : Sendable {
            public let boundingBox: CGRect
            public let landmarks: [ CGPoint ]
        }
        
        static var empty: Output {
            .init(faces: [ ])
        }
        
        public let faces: [ Face ]
    }
}
