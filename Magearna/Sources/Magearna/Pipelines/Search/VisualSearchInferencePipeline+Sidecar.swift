//
//  VisualSearchInferencePipeline+Sidecar.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

import CoreGraphics
import Foundation

extension VisualSearchInferencePipeline {
    struct Sidecar : Sendable {
        let inputSize: CGSize
        
        // immich-ml ignores these configurations and use crop center and bicubic
        let resizeMode: ResizeMode
        let interpolation: Interpolation
        
        let decodeMeans: [ 3 of Float ]
        let decodeScales: [ 3 of Float ]
        
        init(model: InferenceModel, cacheDirectory: URL) throws {
            let preprocessConfiguration = try JSONDecoder()
                .decode(
                    PreprocessConfiguration.self,
                    from: .init(
                        contentsOf: model.directoryURL(in: cacheDirectory)
                            .appending(component: "preprocess_cfg")
                            .appendingPathExtension("json")
                    )
                )
            
            self.inputSize = .init(
                width: preprocessConfiguration.size[0],
                height: preprocessConfiguration.size[1]
            )
            
            self.resizeMode = preprocessConfiguration.resizeMode
            self.interpolation = preprocessConfiguration.interpolation
            
            // In OpenClipVisualEncoder.transform, the to_numpy already normalized to [0, 1]
            self.decodeMeans = .init { preprocessConfiguration.mean[$0] * 255 }
            self.decodeScales = .init { 1 / preprocessConfiguration.std[$0] / 255 }
        }
    }
}

extension VisualSearchInferencePipeline.Sidecar {
    enum Interpolation: String, Decodable, Sendable {
        case bicubic
        case lanczos
    }
    
    enum ResizeMode: String, Decodable, Sendable {
        case shortest
        case squash
    }
}

fileprivate struct PreprocessConfiguration {
    var size: [ 2 of Int ]
    var mean: [ 3 of Float ]
    var std: [ 3 of Float ]
    
    // nearest, box, bilinear, hamming, bicubic, lanczos
    // immich-ml doesn't use it, the resize_pil uses bicubic
    // CIFilter provides bicubicScaleTransform() and lanczosScaleTransform()
    var interpolation: VisualSearchInferencePipeline.Sidecar.Interpolation
    
    // squash: scale and stretch to fill the inputSize
    // shortest: Don't know what it is
    var resizeMode: VisualSearchInferencePipeline.Sidecar.ResizeMode
}

extension PreprocessConfiguration : Decodable {
    enum CodingKeys: CodingKey {
        case size
        case mean
        case std
        case interpolation
        case resize_mode
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            let size = try container.decode(Int.self, forKey: .size)
            self.size = [ size, size ]
        } catch DecodingError.typeMismatch(_, _) {
            self.size = try container.decode(forKey: .size)
        }
        
        self.mean = try container.decode(forKey: .mean)
        self.std = try container.decode(forKey: .std)
        
        self.interpolation = try container.decode(
            VisualSearchInferencePipeline.Sidecar.Interpolation.self,
            forKey: .interpolation
        )
        self.resizeMode = try container.decode(
            VisualSearchInferencePipeline.Sidecar.ResizeMode.self,
            forKey: .resize_mode
        )
    }
}

fileprivate extension KeyedDecodingContainer {
    func decode<let count: Int, Element: Decodable>(forKey key: Key) throws -> [ count of Element ] {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        let result: [ count of Element ] = try .init { span in
            for _ in 0 ..< count {
                span.append(try container.decode(Element.self))
            }
        }
        guard container.isAtEnd else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Expected \(count) elements, but contains more."
            )
        }
        return result
    }
}
