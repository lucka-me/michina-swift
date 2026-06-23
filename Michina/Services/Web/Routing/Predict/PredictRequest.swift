//
//  PredictRequest.swift
//  Michina
//
//  Created by Lucka on 2026-05-20.
//

import CoreImage
import Foundation
import Hummingbird
import Magearna

enum PredictRequest {
    case facialRecognition(input: FacialRecognitionInferencePipeline.Input)
    
    case visualSearch(input: VisualSearchInferencePipeline.Input)
    case textualSearch(input: TextualSearchInferencePipeline.Input)
    
    case characterRecognition(input: CharacterRecognitionInferencePipeline.Input)
}

extension PredictRequest : Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let entries = try container.decode(Entries.self, forKey: .entries)
        
        switch entries.key {
        case .facialRecognition:
            guard
                let detection = entries.value[.detection],
                let detectionMinimalConfidence = detection.options?.minScore,
                let recognition = entries.value[.recognition]
            else {
                throw HTTPError(
                    .unprocessableContent,
                    message: """
                        The object of "\(entries.key.rawValue)" \
                        doesn't contain required fields.
                        """
                )
            }
            
            self = .facialRecognition(
                input: try .init(
                    detectionModel: Self.findModel(
                        suiteCategory: .facialRecognition,
                        suiteName: detection.modelName,
                        modelCategory: .detection
                    ),
                    detectionMinimalConfidence: detectionMinimalConfidence,
                    recognitionModel: Self.findModel(
                        suiteCategory: .facialRecognition,
                        suiteName: recognition.modelName,
                        modelCategory: .recognition
                    ),
                    image: try container.decode(CIImage.self, forKey: .image)
                )
            )
        case .search:
            if let visual = entries.value[.visual] {
                self = .visualSearch(
                    input: .init(
                        model: try Self.findModel(
                            suiteCategory: .search,
                            suiteName: visual.modelName,
                            modelCategory: .visual
                        ),
                        image: try container.decode(CIImage.self, forKey: .image)
                    )
                )
            } else if let textual = entries.value[.textual] {
                self = .textualSearch(
                    input: try .init(
                        model: Self.findModel(
                            suiteCategory: .search,
                            suiteName: textual.modelName,
                            modelCategory: .textual
                        ),
                        language: textual.options?.language,
                        text: container.decode(String.self, forKey: .text)
                    )
                )
            } else {
                throw HTTPError(
                    .unprocessableContent,
                    message: "The search doesn't contains supported model type."
                )
            }
        case .characterRecognition:
            guard
                let detection = entries.value[.detection],
                let detectionMinimalConfidence = detection.options?.minScore,
                let detectionMaximalResolution = detection.options?.maxResolution,
                let recognition = entries.value[.recognition],
                let recognitionMinimalConfidence = recognition.options?.minScore
            else {
                throw HTTPError(
                    .unprocessableContent,
                    message: """
                        The object of "\(entries.key.rawValue)" \
                        doesn't contain required fields.
                        """
                )
            }
            
            self = .characterRecognition(
                input: try .init(
                    detectionModel: Self.findModel(
                        suiteCategory: .characterRecognition,
                        suiteName: detection.modelName,
                        modelCategory: .detection
                    ),
                    detectionMinimalConfidence: detectionMinimalConfidence,
                    detectionMaximalResolution: detectionMaximalResolution,
                    recognitionModel: Self.findModel(
                        suiteCategory: .characterRecognition,
                        suiteName: recognition.modelName,
                        modelCategory: .recognition
                    ),
                    recognitionMinimalConfidence: recognitionMinimalConfidence,
                    image: try container.decode(CIImage.self, forKey: .image)
                )
            )
        }
    }
}

extension PredictRequest {
    var category: InferenceModelSuite.Category {
        switch self {
        case .facialRecognition(_): .facialRecognition
        case .visualSearch(_), .textualSearch(_): .search
        case .characterRecognition(_): .characterRecognition
        }
    }
}

fileprivate extension PredictRequest {
    typealias ModelSuiteCategory = InferenceModelSuite.Category
    typealias ModelCategory = InferenceModel.Category
    
    enum CodingKeys: CodingKey {
        case entries
        case image
        case text
    }
}

fileprivate extension PredictRequest {
    static func findModel(
        suiteCategory: ModelSuiteCategory,
        suiteName: String,
        modelCategory: ModelCategory
    ) throws -> InferenceModel {
        guard
            let model = InferenceModel.find(
                suiteCategory: suiteCategory,
                suiteName: suiteName,
                modelCategory: modelCategory
            )
        else {
            throw HTTPError(
                .notImplemented,
                message: """
                    The requested model \
                    "\(suiteCategory.rawValue)/\(suiteName)/\(modelCategory.rawValue)" \
                    is not supported.
                    """
            )
        }
        
        return model
    }
}

fileprivate extension KeyedDecodingContainer {
    func decode(_ type: Entries.Type, forKey key: Key) throws -> Entries {
        var object = try JSONDecoder()
            .decode(
                [ String : [ String : Entry ] ].self,
                from: try decode(Data.self, forKey: key)
            )
        guard let onlyField = object.popFirst(), object.isEmpty else {
            throw DecodingError.typeMismatch(
                type,
                .init(
                    codingPath: codingPath,
                    debugDescription: "Invalid number of objects found, expected one.",
                    underlyingError: nil
                )
            )
        }
        guard let key = InferenceModelSuite.Category(rawValue: onlyField.key) else {
            throw DecodingError.typeMismatch(
                InferenceModelSuite.Category.self,
                .init(
                    codingPath: codingPath,
                    debugDescription: "Invalid key: \(onlyField.key).",
                    underlyingError: nil
                )
            )
        }
        return (
            key: key,
            value: try onlyField.value.reduce(into: [ : ]) { partial, element in
                guard let key = InferenceModel.Category(rawValue: element.key) else {
                    throw DecodingError.typeMismatch(
                        InferenceModel.Category.self,
                        .init(
                            codingPath: codingPath,
                            debugDescription: """
                                Invalid key in \(onlyField.key): \(element.key).
                                """,
                            underlyingError: nil
                        )
                    )
                }
                partial[key] = element.value
            }
        )
    }
    
    func decode(_: CIImage.Type, forKey key: Key) throws -> CIImage {
        let data = try decode(Data.self, forKey: key)
        guard let image = CIImage(data: data) else {
            throw HTTPError(
                .unprocessableContent,
                message: "Unable to decode the image part."
            )
        }
        return image
    }
}

fileprivate typealias Entries = (
    key: InferenceModelSuite.Category,
    value: [ InferenceModel.Category : Entry ]
)

fileprivate struct Entry : Decodable {
    struct Options : Decodable {
        var language: String?
        var minScore: Float?
        var maxResolution: Int?
    }
    
    var modelName: String
    var options: Options?
}
