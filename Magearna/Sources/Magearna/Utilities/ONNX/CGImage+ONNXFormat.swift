//
//  CGImage+ONNXFormat.swift
//  Magearna
//
//  Created by Lucka on 2026-05-22.
//

import Accelerate

extension CGImage {
    func decodeForONNX(gamma: Gamma, reverseChannels: Bool = false) throws -> Data {
        var imageFormat = vImage_CGImageFormat(
            bitsPerComponent: 32,
            bitsPerPixel: 32 * Self.decodePixelFormat.channelCount,
            colorSpace: self.colorSpace ?? Self.defaultColorSpace,
            bitmapInfo: .init(
                alpha: .none,
                component: .float,
                byteOrder: .order32Host,    // NOT .orderDefault
                pixelFormat: .packed
            )
        )!
        let imageBuffer = try vImage.PixelBuffer(
            cgImage: self,
            cgImageFormat: &imageFormat,
            pixelFormat: Self.decodePixelFormat
        )
        
        if !gamma.isIdentity {
            // cv2.dnn.blobFromImage(image, scale, size, (mean, mean, mean), swapRB=True)
            // cv2: ([0, 255] - mean) * scale
            // vImage: [0, 1] * scale + bias
            imageBuffer.applyGamma(
                linearParameters: gamma.parameters,
                exponentialParameters: (1, 0, 1, 0),
                boundary: 2.0,
                destination: imageBuffer
            )
        }
        
        // Convert to planar format, like matrix (batchs = 1, channels, Height, Width)
        // vImage buffer is horizontially aligned to underlying device, the actual width is larger
        // than the image's width, so we should not read from the buffer pointer directly but
        // from the array copy.
        let planarBuffers: [ vImage.PixelBuffer<vImage.PlanarF> ]
        if reverseChannels {
            planarBuffers = imageBuffer.planarBuffers().reversed()
        } else {
            planarBuffers = imageBuffer.planarBuffers()
        }
        
        return planarBuffers
            .reduce(into: Data()) { partial, buffer in
                buffer.array.withUnsafeBufferPointer { pointer in
                    partial.append(pointer)
                }
            }
    }
    
    func decodeForONNX(gammas: [ 3 of Gamma]) throws -> Data {
        var imageFormat = vImage_CGImageFormat(
            bitsPerComponent: 32,
            bitsPerPixel: 32 * Self.decodePixelFormat.channelCount,
            colorSpace: self.colorSpace ?? Self.defaultColorSpace,
            bitmapInfo: .init(
                alpha: .none,
                component: .float,
                byteOrder: .order32Host,    // NOT .orderDefault
                pixelFormat: .packed
            )
        )!
        let imageBuffer = try vImage.PixelBuffer(
            cgImage: self,
            cgImageFormat: &imageFormat,
            pixelFormat: Self.decodePixelFormat
        )
        
        return imageBuffer
            .planarBuffers()
            .enumerated()
            .reduce(into: Data()) { partial, buffer in
                let gamma = gammas[buffer.offset]
                if !gamma.isIdentity {
                    buffer.element.applyGamma(
                        linearParameters: gamma.parameters,
                        exponentialParameters: (1, 0, 1, 0),
                        boundary: 2.0,
                        destination: buffer.element
                    )
                }
                
                buffer.element.array.withUnsafeBufferPointer { pointer in
                    partial.append(pointer)
                }
            }
    }
}

extension CGImage {
    struct Gamma : Sendable {
        let parameters: (scale: Float, bias: Float)
        
        private init(scale: Float, bias: Float) {
            self.parameters = (scale, bias)
        }
    }
}

extension CGImage.Gamma {
    static var identity: Self {
        .init(scale: 1, bias: 0)
    }
    
    static func openCV(scaleFactor: Float, mean: Float) -> Self {
        .init(
            scale: scaleFactor * 255,
            bias: -mean * scaleFactor
        )
    }
    
    static func range(_ range: ClosedRange<Float>) -> Self {
        .init(
            scale: range.upperBound - range.lowerBound,
            bias: range.lowerBound
        )
    }
}

fileprivate extension CGImage {
    static let defaultColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    static let decodePixelFormat = vImage.InterleavedFx3.self
}

fileprivate extension CGImage.Gamma {
    var isIdentity: Bool {
        parameters.scale == 1 && parameters.bias == .zero
    }
}
