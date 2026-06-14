//
//  VisualSearchSidecar.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

import CoreGraphics
import Foundation

struct VisualSearchSidecar : Sendable {
    let inputSize: CGSize
    
    // immich-ml ignores these configurations and use crop center and bicubic
    let resizeMode: ResizeMode
    let interpolation: Interpolation
    
    let decodeMean: Float
    let decodeScale: Float
    
    init(model: InferenceModel, cacheDirectory: URL) throws {
        let preprocessConfigurationURL = model.directoryURL(in: cacheDirectory)
            .appending(component: "preprocess_cfg")
            .appendingPathExtension("json")
        let preprocessConfiguration = try JSONDecoder()
            .decode(
                PreprocessConfiguration.self,
                from: .init(contentsOf: preprocessConfigurationURL)
            )
        
        guard
            let resizeMode = ResizeMode(
                rawValue: preprocessConfiguration.resize_mode
            )
        else {
            fatalError(
                "Unsupported resize mode: \(preprocessConfiguration.resize_mode)"
            )
        }
        guard
            let interpolation = Interpolation(
                rawValue: preprocessConfiguration.interpolation
            )
        else {
            fatalError(
                "Unsupported intermolation: \(preprocessConfiguration.interpolation)"
            )
        }
        
        self.inputSize = .init(
            width: preprocessConfiguration.size[0],
            height: preprocessConfiguration.size[1]
        )
        
        self.resizeMode = resizeMode
        self.interpolation = interpolation
        
        self.decodeMean = preprocessConfiguration.mean[0]
        self.decodeScale = 1 / preprocessConfiguration.std[0]
    }
}

extension VisualSearchSidecar {
    enum Interpolation: String, Sendable {
        case bicubic
        case lanczos
    }
    
    enum ResizeMode: String, Sendable {
        case squash
    }
}

fileprivate struct PreprocessConfiguration : Decodable {
    var size: [ Int ]
    var mean: [ Float ]
    var std: [ Float ]
    
    // nearest, box, bilinear, hamming, bicubic, lanczos
    // immich-ml doesn't use it, the resize_pil uses bicubic
    // CIFilter provides bicubicScaleTransform() and lanczosScaleTransform()
    var interpolation: String
    
    // squash: scale and stretch to fill the inputSize
    // shortest: Don't know what it is
    var resize_mode: String
}
