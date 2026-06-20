//
//  InferenceModelSuite+All.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

public extension InferenceModelSuite {
    static let all: [ Category : [ InferenceModelSuite ] ] = [
        .facialRecognition : Array {
            immichApp(in: .facialRecognition, areVerified: true) {
                "antelopev2"
                "buffalo_l"
                "buffalo_m"
                "buffalo_s"
            }
            apple(
                in: .facialRecognition,
                name: "apple-vision",
                modelCategories: [ .detection ]
            )
        },
        .search: Array {
            immichApp(in: .search) {
                "RN101__openai"
                "RN101__yfcc15m"
                
                "RN50__cc12m"
                "RN50__openai"
                "RN50__yfcc15m"
                "RN50x16__openai"
                "RN50x4__openai"
                "RN50x64__openai"
                
                "ViT-B-16-SigLIP-256__webli"
                "ViT-B-16-SigLIP-384__webli"
                "ViT-B-16-SigLIP-512__webli"
                "ViT-B-16-SigLIP-i18n-256__webli"
                "ViT-B-16-SigLIP__webli"
                
                "ViT-B-16-plus-240__laion400m_e31"
                "ViT-B-16-plus-240__laion400m_e32"
                
                "ViT-B-16__laion400m_e31"
                "ViT-B-16__laion400m_e32"
                
                "ViT-B-16__openai"
            }
            immichApp(in: .search, areVerified: false) {
                // TODO: Verify all models...
                "ViT-B-32__laion2b-s34b-b79k"
                "ViT-B-32__laion2b_e16"
                "ViT-B-32__laion400m_e31"
                "ViT-B-32__laion400m_e32"
                "ViT-B-32__openai"
                
                "ViT-H-14-378-quickgelu__dfn5b"
                "ViT-H-14-quickgelu__dfn5b"
                "ViT-H-14__laion2b-s32b-b79k"
                "ViT-L-14-336__openai"
                "ViT-L-14-quickgelu__dfn2b"
                "ViT-L-14__laion2b-s32b-b82k"
                "ViT-L-14__laion400m_e31"
                "ViT-L-14__laion400m_e32"
                "ViT-L-14__openai"
                "ViT-L-16-SigLIP-256__webli"
                "ViT-L-16-SigLIP-384__webli"
                
                "ViT-SO400M-14-SigLIP-384__webli"
                
                "XLM-Roberta-Base-ViT-B-32__laion5b_s13b_b90k"
                "XLM-Roberta-Large-ViT-H-14__frozen_laion5b_s13b_b90k"
                
                "nllb-clip-base-siglip__mrl"
                "nllb-clip-base-siglip__v1"
                "nllb-clip-large-siglip__mrl"
                "nllb-clip-large-siglip__v1"
            }
            immichApp(in: .search) {
                "ViT-B-16-SigLIP2__webli"
            }
            immichApp(in: .search, areVerified: false) {
                "ViT-B-32-SigLIP2-256__webli"
                "ViT-L-16-SigLIP2-256__webli"
                "ViT-L-16-SigLIP2-384__webli"
                "ViT-L-16-SigLIP2-512__webli"
                
                "ViT-SO400M-14-SigLIP2-378__webli"
                "ViT-SO400M-14-SigLIP2__webli"
                "ViT-SO400M-16-SigLIP2-256__webli"
            }
            immichApp(in: .search, compatibility: .inefficient) {
                "ViT-SO400M-16-SigLIP2-384__webli"
            }
            immichApp(in: .search, areVerified: false) {
                "ViT-SO400M-16-SigLIP2-512__webli"
                
                "ViT-gopt-16-SigLIP2-256__webli"
                "ViT-gopt-16-SigLIP2-384__webli"
                
                "LABSE-Vit-L-14"
                "XLM-Roberta-Large-Vit-B-16Plus"
                "XLM-Roberta-Large-Vit-B-32"
                "XLM-Roberta-Large-Vit-L-14"
            }
        },
        .characterRecognition: Array {
            // Failed to parse the model specification. Error: Unable to parse ML Program: in
            // operation MaxPool.0: ceil_mode must be False when pad_type is equal to same
            rapidOCR(compatibility: .incompatible) { "PP-OCRv5_server" }
            rapidOCR {
                "PP-OCRv5_mobile"
                "EN__PP-OCRv5_mobile"
                "EL__PP-OCRv5_mobile"
                "KOREAN__PP-OCRv5_mobile"
                "LATIN__PP-OCRv5_mobile"
                "ESLAV__PP-OCRv5_mobile"
                "TH__PP-OCRv5_mobile"
            }
            apple(
                in: .characterRecognition,
                name: "apple-vision",
                areVerified: false,
                modelCategories: [ .detection, .recognition ]
            )
        },
    ]
}

fileprivate extension InferenceModelSuite {
    @ArrayBuilder<Self>
    static func apple(
        in category: Category,
        name: String,
        areVerified: Bool = true,
        modelCategories: [ InferenceModel.Category ],
    ) -> [ Self ] {
        .init(
            category: category,
            name: name,
            provider: .apple,
            isVerified: areVerified,
            models: modelCategories.reduce(into: [ : ]) {
                $0[$1] = .init(
                    suiteCategory: category,
                    suiteName: name,
                    category: $1,
                    provider: .apple,
                    compatibility: .compatible
                )
            }
        )
    }
    
    @ArrayBuilder<Self>
    static func immichApp(
        in category: Category,
        areVerified: Bool = true,
        compatibility: InferenceModel.Compatibility = .compatible,
        @ArrayBuilder<String> names: () -> [ String ]
    ) -> [ Self ] {
        for name in names() {
            .init(
                category: category,
                name: name,
                provider: .immichApp,
                isVerified: areVerified,
                models: InferenceModel.create(
                    suiteCategory: category,
                    suiteName: name,
                    provider: .immichApp,
                    compatibility: compatibility
                )
            )
        }
    }
    
    @ArrayBuilder<Self>
    static func rapidOCR(
        areVerified: Bool = true,
        compatibility: InferenceModel.Compatibility = .compatible,
        @ArrayBuilder<String> names: () -> [ String ]
    ) -> [ Self ] {
        for name in names() {
            .init(
                category: .characterRecognition,
                name: name,
                provider: .rapidOCR,
                isVerified: areVerified,
                models: InferenceModel.create(
                    suiteCategory: .characterRecognition,
                    suiteName: name,
                    provider: .immichApp,
                    compatibility: compatibility
                )
            )
        }
    }
}

fileprivate extension InferenceModel {
    static func create(
        suiteCategory: InferenceModelSuite.Category,
        suiteName: String,
        provider: InferenceModelSuite.Provider,
        compatibility: Compatibility
    ) -> [ Category : Self ] {
        let categories: [ InferenceModel.Category ] = switch suiteCategory {
        case .facialRecognition, .characterRecognition:
            [ .detection, .recognition ]
        case .search:
            [ .textual, .visual ]
        }
        return categories.reduce(into: [ : ]) {
            $0[$1] = .init(
                suiteCategory: suiteCategory,
                suiteName: suiteName,
                category: $1,
                provider: provider,
                compatibility: compatibility
            )
        }
    }
}
