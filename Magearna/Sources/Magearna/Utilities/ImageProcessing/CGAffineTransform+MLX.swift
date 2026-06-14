//
//  CGAffineTransform+MLX.swift
//  Magearna
//
//  Created by Lucka on 2026-05-25.
//

import CoreGraphics
import MLX

extension CGAffineTransform {
    static func similarityTransform(
        from source: [ CGPoint ],
        to destination: [ CGPoint ]
    ) -> CGAffineTransform {
        precondition(
            source.count == destination.count,
            "Size of source and destination should be equal."
        )
        let shape = [ source.count, 2 ]
        return Device.withDefaultDevice(.cpu) {
            let params = umeyama(
                src: .init(
                    source.flatMap { [ Double($0.x), Double($0.y) ] },
                    shape
                ),
                dst: .init(
                    destination.flatMap { [ Double($0.x), Double($0.y) ] },
                    shape
                )
            )
            
            return .init(
                params[0, 0].item(Double.self), params[1, 0].item(Double.self),
                params[0, 1].item(Double.self), params[1, 1].item(Double.self),
                params[0, 2].item(Double.self), params[1, 2].item(Double.self)
            )
        }
    }
}

fileprivate extension CGAffineTransform {
    static func umeyama(
        src: MLXArray,
        dst: MLXArray
    ) -> MLXArray {
        let dim = 2
        
        let srcMean = src.mean(axis: 0)
        let dstMean = dst.mean(axis: 0)
        
        let srcDemean = src - srcMean
        let dstDemean = dst - dstMean
        
        let a = matmul(dstDemean.T, srcDemean) / src.shape[0]
        
        let d = MLXArray.ones([ dim ], dtype: .float64)
        
        if MLXLinalg.det(a) < 0 {
            d[dim - 1] = .init(-1.0)
        }
        
        let t = MLXArray.eye(dim + 1, dtype: .float64)
        
        let (u, s, v) = MLXLinalg.svd(a)
        
        switch MLXLinalg.matrixRank(a, precalculatedS: s) {
        case 0: fatalError("The rank of \(a) is zero")
        case dim - 1:
            if MLXLinalg.det(u) * MLXLinalg.det(v) > 0 {
                t[ ..<dim, ..<dim ] = matmul(u, v)
            } else {
                let s = d[dim - 1]
                d[dim - 1] = .init(-1.0)
                t[ ..<dim, ..<dim ] = matmul(matmul(u, diag(d)), v)
                d[dim - 1] = s
            }
        default:
            t[ ..<dim, ..<dim ] = matmul(matmul(u, diag(d)), v)
        }
        
        let scale = 1.0 / srcDemean.variance(axis: 0).sum() * matmul(s, d)
        
        t[ ..<dim, dim ] = dstMean - scale * matmul(t[ ..<dim, ..<dim ], srcMean.T)
        t[ ..<dim, ..<dim ] *= scale
        
        return t
    }
}

fileprivate extension MLXLinalg {
    static func det(_ a: MLXArray) -> Double {
        let (_, _, u) = MLXLinalg.lu(a)
        return product(diag(u)).item()
    }
    
    static func matrixRank(_ a: MLXArray, precalculatedS: MLXArray? = nil) -> Int {
        let s: MLXArray
        if let precalculatedS {
            s = precalculatedS
        } else {
            (_, s, _) = svd(a)
        }
        let rtol = Double(max(a.shape[a.ndim - 2], a.shape[a.ndim - 1])) * Double.ulpOfOne
        let tol = s.max(axis: -1, keepDims: true).item(Double.self) * rtol
        return s.count { $0.item(Double.self) > tol }
    }
}
