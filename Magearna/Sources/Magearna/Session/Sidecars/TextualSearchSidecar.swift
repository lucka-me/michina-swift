//
//  TextualSearchSidecar.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

import Foundation
import Tokenizers

struct TextualSearchSidecar : Sendable {
    let tokenizer: Tokenizer
    
    let shouldCanonicalize: Bool
    
    // For NLLB model and tokenizer, the tokenizer will always prepend the id of English to the
    // encoded ids, but we (following immich) will also prepend the language token to the text, so
    // we add 1 to the fixed length, and drop the first id before input to model.
    let shouldPrependLanguage: Bool
    
    init(model: InferenceModel, cacheDirectory: URL) throws {
        self.shouldPrependLanguage = model.suiteName.hasPrefix("nllb")
        
        let directoryURL = model.directoryURL(in: cacheDirectory)
        let decoder = JSONDecoder()
        
        let modelSuiteConfigurations = try decoder.decode(
            ModelSuiteConfigurations.self,
            from: .init(
                contentsOf: directoryURL
                    .deletingLastPathComponent()
                    .appending(component: "config")
                    .appendingPathExtension("json")
            )
        )
        self.shouldCanonicalize = modelSuiteConfigurations.tokenizer_kwargs?.clean == "canonicalize"
        self.tokenizer = try .init(
            fromPath: directoryURL
                .appending(component: "tokenizer")
                .appendingPathExtension("json")
                .path(percentEncoded: false)
        )
        
        let tokenizerConfigurations = try decoder.decode(
            TokenizerConfigurations.self,
            from: .init(
                contentsOf: directoryURL
                    .appending(component: "tokenizer_config")
                    .appendingPathExtension("json")
            )
        )
        
        let length = modelSuiteConfigurations.text_cfg.context_length ?? 77 // Why 77
        if let token = tokenizerConfigurations.pad_token {
            try self.tokenizer.enableFixingLength(
                length + (shouldPrependLanguage ? 1 : 0),
                withPaddingToken: token
            )
        }
    }
}

struct ModelSuiteConfigurations : Decodable {
    struct TextConfigurations : Decodable {
        var context_length: Int?
    }
    
    struct TokenizerArguments : Decodable {
        var clean: String?
    }
    
    var text_cfg: TextConfigurations
    var tokenizer_kwargs: TokenizerArguments?
}

struct TokenizerConfigurations : Decodable {
    var pad_token: String?
}
