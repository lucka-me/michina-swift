//
//  ContoursVision.swift
//  Magearna
//
//  Created by Lucka on 2026-09-01.
//

import Accelerate
import Vision

public enum ContoursVision {
    enum Legacy {
        
    }
}

public extension ContoursVision {
    static func detect(
        in buffer: vImage.PixelBuffer<vImage.PlanarF>
    ) async throws -> [ NormalizedContour ] {
        guard
            let cgImage = buffer.makeCGImage(
                cgImageFormat: .init(
                    bitsPerComponent: 32,
                    bitsPerPixel: 32,
                    colorSpace: .init(name: CGColorSpace.linearGray)!,
                    bitmapInfo: .init(
                        alpha: .none,
                        component: .float,
                        byteOrder: .order32Host
                    )
                )!
            )
        else {
            throw .runtime("Unable to create binary CGImage.")
        }
        
        return if #available(macOS 15.0, *) {
            try await detect(in: cgImage)
        } else {
            try await Legacy.detect(in: cgImage)
        }
    }
}

fileprivate extension ContoursVision {
    @available(macOS 15.0, *)
    static func detect(in cgImage: CGImage) async throws -> [ NormalizedContour ] {
        let handler = ImageRequestHandler(cgImage, orientation: .downMirrored)
        var request = DetectContoursRequest()
        request.detectsDarkOnLight = false
        
        return try await handler
            .perform(request)
            .topLevelContours
            .map(NormalizedContour.init)
    }
}

fileprivate extension ContoursVision.Legacy {
    static func detect(in cgImage: CGImage) async throws -> [ ContoursVision.NormalizedContour ] {
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .downMirrored)
        let request = VNDetectContoursRequest()
        request.detectsDarkOnLight = false
        
        try handler.perform([ request ])
        
        guard let results = request.results else {
            return [ ]
        }
        
        return results
            .flatMap(\.topLevelContours)
            .map(ContoursVision.NormalizedContour.init)
    }
}
