//
//  TextualSearchInferencePipeline.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

import Foundation
import ONNXRuntime
import Tokenizers

public actor TextualSearchInferencePipeline : InferencePipeline {
    public static let category = InferenceModelSuite.Category.search
    
    public private(set) var modelReports: [InferencePipelineModelReport] = [ ]
    
    private let input: Input
    
    private var session: InferenceSession? = nil
    private var sidecar: TextualSearchSidecar? = nil
    
    private var output: Output = [ ]
    
    public init(_ input: Input) {
        self.input = input
    }
    
    public var models: [ InferenceModel ] {
        [ input.model ]
    }
    
    public func prepare(_ sessions: [ InferenceModel.Category : InferenceSession ]) throws {
        guard let session = sessions[.textual] else {
            fatalError("Missing session.")
        }
        
        self.session = session
        guard case let .textualSearch(sidecar) = session.sidecar else {
            fatalError("The session doesn't contain TextualSearchInferencePipeline.Configurations.")
        }
        self.sidecar = sidecar
        
        output.removeAll()
    }
    
    public func run() throws -> Output {
        guard let session, let sidecar else {
            fatalError("TextualSearchInferencePipeline.prepared() was not called.")
        }
        
        let elapse = try ContinuousClock().measure {
            let ids = try sidecar.encode(text: input.text, language: input.language)
            let inputValue = try ORTValue(
                tensorData: .init(data: ids.withUnsafeBufferPointer { .init(buffer: $0) }),
                elementType: .int32,
                shape: [ 1, ids.count as NSNumber ]
            )
            let outputs = try session.session.run(
                withInputs: [ session.inputNames[0] : inputValue ],
                outputNames: .init(session.outputNames),
                runOptions: nil
            )
            
            self.output = try outputs[session.outputNames[0]]!.array()
        }
        modelReports.append(.init(model: input.model, elapse: elapse))
        
        return self.output
    }
}

public extension TextualSearchInferencePipeline {
    typealias Output = [ Float ]
    
    struct Input : Sendable {
        let model: InferenceModel
        
        let language: String
        
        let text: String
        
        public init(model: InferenceModel, language: String, text: String) {
            self.model = model
            self.language = language
            self.text = text
        }
    }
}

fileprivate extension TextualSearchSidecar {
    static let floresCodes: [ String : String ] = [
        "af": "afr_Latn",
        "ar": "arb_Arab",
        "az": "azj_Latn",
        "be": "bel_Cyrl",
        "bg": "bul_Cyrl",
        "ca": "cat_Latn",
        "cs": "ces_Latn",
        "da": "dan_Latn",
        "de": "deu_Latn",
        "el": "ell_Grek",
        "en": "eng_Latn",
        "es": "spa_Latn",
        "et": "est_Latn",
        "fa": "pes_Arab",
        "fi": "fin_Latn",
        "fr": "fra_Latn",
        "he": "heb_Hebr",
        "hi": "hin_Deva",
        "hr": "hrv_Latn",
        "hu": "hun_Latn",
        "hy": "hye_Armn",
        "id": "ind_Latn",
        "it": "ita_Latn",
        "ja": "jpn_Hira",
        "kmr": "kmr_Latn",
        "ko": "kor_Hang",
        "lb": "ltz_Latn",
        "lt": "lit_Latn",
        "lv": "lav_Latn",
        "mfa": "zsm_Latn",
        "mk": "mkd_Cyrl",
        "mn": "khk_Cyrl",
        "mr": "mar_Deva",
        "ms": "zsm_Latn",
        "nb-NO": "nob_Latn",
        "nn": "nno_Latn",
        "nl": "nld_Latn",
        "pl": "pol_Latn",
        "pt-BR": "por_Latn",
        "pt": "por_Latn",
        "ro": "ron_Latn",
        "ru": "rus_Cyrl",
        "sk": "slk_Latn",
        "sl": "slv_Latn",
        "sr-Cyrl": "srp_Cyrl",
        "sv": "swe_Latn",
        "ta": "tam_Taml",
        "te": "tel_Telu",
        "th": "tha_Thai",
        "tr": "tur_Latn",
        "uk": "ukr_Cyrl",
        "ur": "urd_Arab",
        "vi": "vie_Latn",
        "zh-CN": "zho_Hans",
        "zh-Hans": "zho_Hans",
        "zh-TW": "zho_Hant",
    ]
    
    func encode(text: String, language: String) throws -> [ Int32 ] {
        var cleanText = clear(text: text)
        if shouldSpecifyLanguage {
            let floresCode: String
            if let code = Self.floresCodes[language] {
                floresCode = code
            } else if
                let prefix = language.split(separator: "-").first,
                let code = Self.floresCodes[.init(prefix)]
            {
                floresCode = code
            } else {
                floresCode = "eng_Latn"
            }
            cleanText = floresCode + cleanText
        }
        let encoding = try tokenizer.encodeText(cleanText)
        let tokens = encoding.ids.map { Int32($0.uint32Value) }
        return postprocess(tokens: tokens)
    }
    
    private func clear(text: String) -> String {
        let spacesNormalized = text
            .components(separatedBy: .whitespacesAndNewlines)
            .joined(separator: " ")
        return if shouldCanonicalize {
            spacesNormalized.removingCharacters(in: .punctuationCharacters)
        } else {
            spacesNormalized
        }
    }
    
    private func postprocess(tokens: [ Int32 ]) -> [ Int32 ] {
        if tokens.count < contextLength {
            if let paddingTokenID {
                tokens + .init(repeating: paddingTokenID, count: contextLength - tokens.count)
            } else {
                tokens
            }
        } else {
            .init(tokens.prefix(contextLength))
        }
    }
}

fileprivate extension String {
    func removingCharacters(in characterSet: CharacterSet) -> String {
        var result = self
        while let ranges = result.rangeOfCharacter(from: characterSet) {
            result.removeSubrange(ranges)
        }
        return result
    }
}
