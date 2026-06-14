//
//  CGAffineTransform+BLAS.swift
//  Magearna
//
//  Created by Lucka on 2026-05-22.
//

// Note: We keep these codes because they are 10x faster than the MLX implementation, lol

#if canImport(NdArray)
import CoreGraphics
import NdArray

extension CGAffineTransform {
//    static func similarityTransform(
//        from source: [ CGPoint ],
//        to destination: [ CGPoint ],
//        sourceHeight: CGFloat,
//        destinationHeight: CGFloat
//    ) throws -> CGAffineTransform {
//        let params = try umeyama(
//            src: .init(source.map { [ $0.x, sourceHeight - $0.y ] }),
//            dst: .init(destination.map { [ $0.x, destinationHeight - $0.y ] })
//        )
//        
//        return .init(
//            params[0, 0], params[1, 0],
//            params[0, 1], params[1, 1],
//            params[0, 2], params[1, 2]
//        )
//    }
}

fileprivate extension CGAffineTransform {
    static func umeyama(src: Matrix<Double>, dst: Matrix<Double>) throws -> NdArray<Double> {
        let num = src.shape[0] // 5
        let dim = 2
        
        let srcMean = src.columnMeans()
        let dstMean = dst.columnMeans()
        
        let srcDemean = Matrix(copy: src)
        let dstDemean = Matrix(copy: dst)
        for row in 0 ..< num {
            srcDemean[ Slice(row) ] -= srcMean
            dstDemean[ Slice(row) ] -= dstMean
        }
        
        let a = dstDemean.transposed() * srcDemean / Double(src.shape[0]) // A = dst_demean.T @ src_demean / num
        
        let d = Vector<Double>.ones(dim) // d = np.ones((dim,), dtype=np.float64)
        
        if a.determinant() < 0 {
            d[dim - 1] = -1 // d[dim - 1] = -1
        }
        
        let t = Matrix<Double>(eye: dim + 1) // T = np.eye(dim + 1, dtype=np.float64)
        
        let (u, s, v) = try a.svd() // U, S, V = np.linalg.svd(A)
        
        if a.matrixRank(with: s) == dim - 1 { // rank = np.linalg.matrix_rank(A)
            if u.determinant() * v.determinant() > 0 { // if np.linalg.det(U) * np.linalg.det(V) > 0
                t[ ..<dim, ..<dim ] = u * v // T[:dim, :dim] = U @ V
            } else {
                let s = d[dim - 1] // s = d[dim - 1]
                d[dim - 1] = -1 // d[dim - 1] = -1
                t[ ..<dim, ..<dim ] = u * Matrix(diag: d) * v // T[:dim, :dim] = U @ np.diag(d) @ V
                d[dim - 1] = s // d[dim - 1] = s
            }
        } else {
            t[ ..<dim, ..<dim ] = u * Matrix(diag: d) * v // T[:dim, :dim] = U @ np.diag(d) @ V
        }
        
        let scale = (s * d) / srcDemean.columnVariancesSum() // scale = 1.0 / src_demean.var(axis=0).sum() * (S @ d)
        
        t[ ..<dim, Slice(dim) ] = dstMean - scale * (Matrix(t[ ..<dim, ..<dim ]) * srcMean) // T[:dim, dim] = dst_mean - scale * (T[:dim, :dim] @ src_mean.T)
        t[ ..<dim, ..<dim ] *= scale // T[:dim, :dim] *= scale
        
        return t
    }
}

fileprivate extension Matrix where T: ExpressibleByIntegerLiteral {
    convenience init(eye count: Int, order: Contiguous = .C) {
        self.init(empty: [ count, count ])
        for i in 0 ..< count {
            self[i, i] = 1
        }
    }
}

fileprivate extension Matrix where T == Double {
    func columnMeans() -> Vector<T> {
        let rows = shape[0]
        let sum = Vector<T>.zeros(shape[1])
        for row in 0 ..< rows {
            sum += self[ Slice(row) ]
        }
        return sum / T(rows)
    }
    
    func columnVariancesSum() -> T {
        let means = columnMeans()
        let demeans = Matrix(copy: self)
        for row in 0 ..< shape[0] {
            demeans[ Slice(row) ] -= means
        }
        
        for row in 0 ..< shape[0] {
            for col in 0 ..< shape[1] {
                demeans[row, col] = pow(demeans[row, col], 2)
            }
        }
        return demeans.columnMeans().reduce(0, +)
    }
    
    func determinant() -> T {
        // Reference: https://cp-algorithms.com/linear_algebra/determinant-gauss.html
        let n = shape[0]
        let a = Matrix(copy: self)
        var det: T = 1
        for i in 0 ..< n {
            var k = i
            for j in i + 1 ..< n {
                if abs(a[j, i]) > abs(a[k, i]) {
                    k = j
                }
            }
            if abs(a[k, i]) < T.ulpOfOne {
                det = 0
                break
            }
            // swap (a[i], a[k]);
            for col in 0 ..< n {
                let ai = a[i, col]
                a[i, col] = a[k, col]
                a[k, col] = ai
            }
            // END
            if i != k {
                det = -det
            }
            det *= a[i, i]
            for j in i + 1 ..< n {
                a[i, j] /= a[i, i]
            }
            for j in 0 ..< n {
                if j != i, abs(a[j, i]) > T.ulpOfOne {
                    for k in i + 1 ..< n {
                        a[j, k] -= a[i, k] * a[j, i]
                    }
                }
            }
        }
        
        return det
    }
    
    func matrixRank(with s: Vector<T>) -> Int {
        // s is 2x2
        let rtol = T(self.shape.max()!) * T.ulpOfOne // rtol = max(A.shape[-2:]) * finfo(S.dtype).eps
        let tol = s.max()! * rtol // tol = S.max(axis=-1, keepdims=True) * rtol
        return s.count { $0 > tol }
    }
    
    func diag() -> Matrix<T> {
        let result = Matrix<T>.zeros(self.shape)
        for i in 0 ..< shape[0] {
            result[i, i] = self[i, i]
        }
        return result
    }
}
#endif
