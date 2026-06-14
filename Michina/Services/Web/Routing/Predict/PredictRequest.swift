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
        
        let entries = try JSONDecoder()
            .decode(
                [ String : [ String : PredictEntry ] ].self,
                from: try container.decode(Data.self, forKey: .entries)
            )
        
        if let taskEntries = entries[ModelSuiteCategory.facialRecognition] {
            guard
                let detection = taskEntries[ModelCategory.detection],
                let detectionMinimalConfidence = detection.options?.minScore,
                let recognition = taskEntries[ModelCategory.recognition]
            else {
                throw HTTPError(.badRequest, message: "The facial-recognition doesn't contains required entries.")
            }
            guard
                let image = CIImage(data: try container.decode(Data.self, forKey: .image))
            else {
                throw HTTPError(.badRequest, message: "Unable to decode the image part.")
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
                    image: image
                )
            )
        } else if let taskEntries = entries[ModelSuiteCategory.search] {
            if let visual = taskEntries[ModelCategory.visual] {
                guard
                    let image = CIImage(data: try container.decode(Data.self, forKey: .image))
                else {
                    throw HTTPError(.badRequest, message: "Unable to decode the image part.")
                }
                self = .visualSearch(
                    input: .init(
                        model: try Self.findModel(
                            suiteCategory: .search,
                            suiteName: visual.modelName,
                            modelCategory: .visual
                        ),
                        image: image
                    )
                )
            } else if let textual = taskEntries[ModelCategory.textual] {
                guard let language = textual.options?.language else {
                    throw HTTPError(.badRequest, message: "The clip doesn't contains required entries.")
                }
                self = .textualSearch(
                    input: try .init(
                        model: Self.findModel(
                            suiteCategory: .search,
                            suiteName: textual.modelName,
                            modelCategory: .textual
                        ),
                        language: language,
                        text: container.decode(String.self, forKey: .text)
                    )
                )
            } else {
                throw HTTPError(.notImplemented, message: "The service only supports clip.textual yet.")
            }
        } else if let taskEntries = entries[ModelSuiteCategory.characterRecognition] {
            guard
                let detection = taskEntries[ModelCategory.detection],
                let detectionMinimalConfidence = detection.options?.minScore,
                let detectionMaximalResolution = detection.options?.maxResolution,
                let recognition = taskEntries[ModelCategory.recognition],
                let recognitionMinimalConfidence = recognition.options?.minScore
            else {
                throw HTTPError(.badRequest, message: "The facial-recognition doesn't contains required entries.")
            }
            guard
                let image = CIImage(data: try container.decode(Data.self, forKey: .image))
            else {
                throw HTTPError(.badRequest, message: "Unable to decode the image part.")
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
                    image: image
                )
            )
        } else {
            throw HTTPError(.notImplemented, message: "No known task.")
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
                message: "The model \(suiteCategory.rawValue)/\(suiteName)/\(modelCategory.rawValue) is not supported."
            )
        }
        
        return model
    }
}

fileprivate struct PredictEntry : Decodable {
    struct Options : Decodable {
        var language: String?
        var minScore: Float?
        var maxResolution: Int?
    }
    
    var modelName: String
    var options: Options?
}
