//
//  TextualSearchSidecar.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

import Foundation
import Hub
import Tokenizers

struct TextualSearchSidecar : Sendable {
    let tokenizer: Tokenizer
    
    let shouldCanonicalize: Bool
    let shouldSpecifyLanguage: Bool
    
    let contextLength: Int
    let paddingTokenID: Int32?
    
    init(model: InferenceModel, cacheDirectory: URL) throws {
        self.shouldSpecifyLanguage = model.suiteName.hasPrefix("nllb")
        
        let directoryURL = model.directoryURL(in: cacheDirectory)
        let decoder = JSONDecoder()
        
        let modelSuiteConfig = try decoder.decode(
            Config.self,
            from: .init(
                contentsOf: directoryURL
                    .deletingLastPathComponent()
                    .appending(component: "config")
                    .appendingPathExtension("json")
            )
        )
        self.contextLength = modelSuiteConfig["text_cfg"]["context_length"].integer(or: 77) // Why 77
        self.shouldCanonicalize = modelSuiteConfig["tokenizer_kwargs"]["clean"].string(or: "") == "canonicalize"
        
        let tokenizerConfig = try decoder.decode(
            Config.self,
            from: .init(
                contentsOf: directoryURL
                    .appending(component: "tokenizer_config")
                    .appendingPathExtension("json")
            )
        )
        
        self.tokenizer = try AutoTokenizer.from(
            tokenizerConfig: tokenizerConfig,
            tokenizerData: try decoder.decode(
                Config.self,
                from: .init(
                    contentsOf: directoryURL
                        .appending(component: "tokenizer")
                        .appendingPathExtension("json")
                )
            )
        )
        self.paddingTokenID = if
            let token = tokenizerConfig["pad_token"].string(),
            let id = self.tokenizer.convertTokenToId(token)
        {
            .init(id)
        } else {
            nil
        }
    }
}
