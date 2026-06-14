//
//  InferencePipelineOutputMetric.swift
//  Michina
//
//  Created by Lucka on 2026-06-06.
//

import Foundation
import Magearna

enum InferencePipelineOutputMetric {
    case facialRecognition(metric: FacialRecognition)
    case characterRecognition(metric: CharacterRecognition)
}

extension InferencePipelineOutputMetric {
    struct FacialRecognition {
        fileprivate(set) var imageWithFacesCount = 0
        fileprivate(set) var faceCount = 0
    }
    
    struct CharacterRecognition {
        fileprivate(set) var imageWithCharactersCount = 0
        fileprivate(set) var characterBoxCount = 0
        fileprivate(set) var characterCount = 0
    }
}

extension InferencePipelineOutputMetric {
    struct Report : Sendable {
        fileprivate let content: Content
        
        fileprivate init(content: Content) {
            self.content = content
        }
    }
    
    mutating func record(report: Report) {
        switch self {
        case .facialRecognition(var metric):
            guard case let .facialRecognition(faceCount) = report.content else {
                return
            }
            if faceCount > 0 {
                metric.imageWithFacesCount += 1
            }
            metric.faceCount += faceCount
            self = .facialRecognition(metric: metric)
        case .characterRecognition(var metric):
            guard
                case let .characterRecognition(characterBoxCount, characterCount) = report.content
            else {
                return
            }
            if characterBoxCount > 0 {
                metric.imageWithCharactersCount += 1
            }
            metric.characterBoxCount += characterBoxCount
            metric.characterCount += characterCount
            self = .characterRecognition(metric: metric)
        }
    }
}

extension InferencePipelineOutputMetric.Report {
    @inlinable static func create<Output: Sendable>(
        from output: Output
    ) -> Self? {
        if let output = output as? FacialRecognitionInferencePipeline.Output {
            .init(
                content: .facialRecognition(faceCount: output.faces.count)
            )
        } else if let output = output as? CharacterRecognitionInferencePipeline.Output {
            .init(
                content: .characterRecognition(
                    characterBoxCount: output.characterBoxes.count,
                    characterCount: output.characterBoxes.map(\.text.item.count).reduce(0, +)
                )
            )
        } else {
            nil
        }
    }
}

fileprivate extension InferencePipelineOutputMetric.Report {
    enum Content {
        case facialRecognition(faceCount: Int)
        case characterRecognition(characterBoxCount: Int, characterCount: Int)
    }
}
