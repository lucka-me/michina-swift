//
//  RapidCharacterRecognition+Sidecar.swift
//  Magearna
//
//  Created by Lucka on 2026-05-31.
//

import Foundation
import SwiftProtobuf

extension RapidCharacterRecognition {
    struct Sidecar : Sendable {
        let characters: [ String ]
        
        init(model: InferenceModel, cacheDirectory: URL) throws {
            let modelData = try ONNXPartialModel(
                serializedBytes: Data(contentsOf: model.modelFileURL(in: cacheDirectory)),
                options: .discardUnknownFields(true)
            )
            
            guard
                let characterProperty = modelData.metadataProps
                    .first(where: { $0.key == "character" })
            else {
                fatalError("No characters metadata property presents in the model.")
            }
            
            self.characters = [ "" ]
                + characterProperty.value.components(separatedBy: .newlines)
                + [ " " ]
        }
    }
}
