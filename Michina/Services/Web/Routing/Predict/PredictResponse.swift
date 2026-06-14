//
//  PredictResponse.swift
//  Michina
//
//  Created by Lucka on 2026-05-20.
//

import CoreGraphics
import Foundation
import Hummingbird
import Magearna

enum PredictResponse {
    case facialRecognition(output: FacialRecognitionInferencePipeline.Output, imageSize: CGSize)
    
    case visualSearch(output: VisualSearchInferencePipeline.Output, imageSize: CGSize)
    case textualSearch(output: TextualSearchInferencePipeline.Output)
    
    case characterRecognition(output: CharacterRecognitionInferencePipeline.Output, imageSize: CGSize)
}

extension PredictResponse : Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .facialRecognition(let output, let imageSize):
            try container.encode(
                output.faces.map { FacialRecognitionItem(face: $0) },
                forKey: .facialRecognition
            )
            try container.encode(Int(imageSize.height), forKey: .imageHeight)
            try container.encode(Int(imageSize.width), forKey: .imageWidth)
        case .visualSearch(let output, let imageSize):
            try container.encode(
                String(data: Self.arrayEncoder.encode(output), encoding: .utf8),
                forKey: .search
            )
            try container.encode(Int(imageSize.height), forKey: .imageHeight)
            try container.encode(Int(imageSize.width), forKey: .imageWidth)
        case .textualSearch(let output):
            try container.encode(
                String(data: Self.arrayEncoder.encode(output), encoding: .utf8),
                forKey: .search
            )
        case .characterRecognition(let output, let imageSize):
            try container.encode(
                CharacterRecognitionResults(from: output, imageSize: imageSize),
                forKey: .characterRecognition
            )
            try container.encode(Int(imageSize.height), forKey: .imageHeight)
            try container.encode(Int(imageSize.width), forKey: .imageWidth)
        }
    }
}

extension PredictResponse : ResponseEncodable {
}

fileprivate extension PredictResponse {
    enum CodingKeys: String, CodingKey {
        case facialRecognition = "facial-recognition"
        case search = "clip"
        case characterRecognition = "ocr"
        
        case imageHeight
        case imageWidth
    }
    
    static let arrayEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [ ]
        return encoder
    }()
}

fileprivate struct FacialRecognitionItem : Encodable {
    struct BoundingBox : Encodable {
        let x1: Int
        let y1: Int
        
        let x2: Int
        let y2: Int
    }
    
    private enum CodingKeys : CodingKey {
        case boundingBox
        case embedding
        case score
    }
    
    let boundingBox: BoundingBox
    let embedding: [ Float ]
    let score: Float
    
    init(face: FacialRecognitionInferencePipeline.Output.Face) {
        self.boundingBox = .init(
            x1: .init(round(face.geometry.item.boundingBox.minX)),
            y1: .init(round(face.geometry.item.boundingBox.minY)),
            x2: .init(round(face.geometry.item.boundingBox.maxX)),
            y2: .init(round(face.geometry.item.boundingBox.maxY))
        )
        self.embedding = face.embedding
        self.score = face.geometry.confidence
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(
            String(
                data: PredictResponse.arrayEncoder.encode(embedding),
                encoding: .utf8
            ),
            forKey: .embedding
        )
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(score, forKey: .score)
    }
}

fileprivate struct CharacterRecognitionResults : Encodable {
    let text: [ String ]
    let textScore: [ Float ]
    
    let box: [ CGFloat ]
    let boxScore: [ Float ]
    
    init(from output: CharacterRecognitionInferencePipeline.Output, imageSize: CGSize) {
        self.text = output.characterBoxes.map(\.text.item)
        self.textScore = output.characterBoxes.map(\.text.confidence)
        self.box = output.characterBoxes.flatMap { box in
            box.shape.item.points.flatMap { point in
                [ point.x / imageSize.width, point.y / imageSize.height ]
            }
        }
        self.boxScore = output.characterBoxes.map(\.shape.confidence)
    }
}
