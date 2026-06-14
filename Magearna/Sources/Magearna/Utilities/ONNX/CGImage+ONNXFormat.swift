//
//  CGImage+ONNXFormat.swift
//  Magearna
//
//  Created by Lucka on 2026-05-22.
//

import Accelerate

extension CGImage {
    func decodeForONNX(mean: Float, scale: Float) throws -> Data {
        var imageFormat = vImage_CGImageFormat(
            bitsPerComponent: 32,
            bitsPerPixel: 32 * Self.pixelFormat.channelCount,
            colorSpace: .init(name: CGColorSpace.sRGB)!,
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
            pixelFormat: Self.pixelFormat
        )
        
        // cv2.dnn.blobFromImage(image, scale, size, (mean, mean, mean), swapRB=True)
        imageBuffer.applyGamma(
            linearParameters: (scale: scale * 255, bias: -mean * scale),
            exponentialParameters: (1, 0, 1, 0),
            boundary: 2.0,
            destination: imageBuffer
        )
        
        // Convert to planar format, like matrix (batchs = 1, channels, Height, Width)
        // vImage buffer is horizontially aligned to underlying device, the actual width is larger
        // than the image's width, so we should not read from the buffer pointer directly but
        // from the array copy.
        return imageBuffer
            .planarBuffers()
            .reduce(into: Data()) { partial, buffer in
                buffer.array.withUnsafeBufferPointer { pointer in
                    partial.append(.init(buffer: pointer))
                }
            }
    }
}

fileprivate extension CGImage {
    static let pixelFormat = vImage.InterleavedFx3.self
}
