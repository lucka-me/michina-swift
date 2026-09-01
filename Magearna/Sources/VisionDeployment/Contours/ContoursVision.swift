//
//  ContoursVision.swift
//  Magearna
//
//  Created by Lucka on 2026-09-01.
//

import Accelerate
import Vision

public enum ContoursVision {
    
}

public extension ContoursVision {
    static func detect(in buffer: vImage.PixelBuffer<vImage.PlanarF>) async throws -> [ Contour ] {
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
        
        let handler = ImageRequestHandler(cgImage, orientation: .downMirrored)
        var request = DetectContoursRequest()
        request.detectsDarkOnLight = false
        let contours = try await handler.perform(request)
        
        return contours.topLevelContours.map { contour in
            .init(
                normalizedBoundingBox: contour.boundingBox,
                normalizedPath: contour.normalizedPath,
                normalizedPoints: contour.points
            )
        }
    }
}
