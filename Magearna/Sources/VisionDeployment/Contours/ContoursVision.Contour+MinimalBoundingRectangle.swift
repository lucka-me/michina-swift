//
//  ContoursVision.Contour+MinimalBoundingRectangle.swift
//  Magearna
//
//  Created by Lucka on 2026-09-01.
//

import DequeModule
import Geometry
import Vision

public extension ContoursVision.Contour {
    func minimalBounding<Rectangle: RectangleRepresentable>(
        _ type: Rectangle.Type = Rectangle.self,
        in imageSize: CGSize
    ) -> Rectangle where Rectangle.Point == CGPoint {
        if #available(macOS 15.0, *) {
            let normalized = normalizedMinimalBounding(RectangleObservation.self)
            return .init(
                topLeft: normalized.bottomLeft.toImageCoordinates(imageSize),
                topRight: normalized.bottomRight.toImageCoordinates(imageSize),
                bottomRight: normalized.topRight.toImageCoordinates(imageSize),
                bottomLeft: normalized.topLeft.toImageCoordinates(imageSize)
            )
        } else {
            let normalized = normalizedMinimalBounding(type)
            
            let width = Int(imageSize.width)
            let height = Int(imageSize.height)
            
            return .init(
                topLeft: VNImagePointForNormalizedPoint(normalized.bottomLeft, width, height),
                topRight: VNImagePointForNormalizedPoint(normalized.bottomRight, width, height),
                bottomRight: VNImagePointForNormalizedPoint(normalized.topRight, width, height),
                bottomLeft: VNImagePointForNormalizedPoint(normalized.topLeft, width, height)
            )
        }
    }
}

fileprivate typealias Edge = (SIMD2<Double>, SIMD2<Double>)

fileprivate extension ContoursVision.Contour {
    func normalizedMinimalBounding<Rectangle: RectangleRepresentable>(
        _ type: Rectangle.Type = Rectangle.self
    ) -> Rectangle {
        let edges = convexHullEdges()
        let vertices = edges.map(\.0)
        
        var minimalArea = Double.infinity
        var minimalRectangle: Rectangle? = nil
        for edge in edges {
            guard
                let (rectangle, area) = Self.rectangle(
                    Rectangle.self,
                    mapping: vertices,
                    to: edge,
                    maximalArea: minimalArea
                )
            else {
                continue
            }
            
            minimalArea = area
            minimalRectangle = rectangle
        }
        
        return minimalRectangle!
    }
}

fileprivate extension ContoursVision.Contour {
    func convexHullEdges() -> [ Edge ] {
        // Reference: ON-LINE CONSTRUCTION OF THE CONVEX HULL OF A SIMPLE POLYLINE
        //            Avraham A. MELKMAN
        // https://www.ime.usp.br/~walterfm/cursos/mac0331/2006/melkman.pdf
        
        var deque = Deque<SIMD2<Double>>(minimumCapacity: normalizedPoints.count)
        // Left > 0, Right < 0, opposite to the article
        
        if cross(normalizedPoints[0], normalizedPoints[1], normalizedPoints[2]) < 0 {
            deque.append(normalizedPoints[0])
            deque.append(normalizedPoints[1])
        } else {
            deque.append(normalizedPoints[1])
            deque.append(normalizedPoints[0])
        }
        deque.append(normalizedPoints[2])
        deque.prepend(normalizedPoints[2])
        
        for point in normalizedPoints[3...] {
            guard
                cross(point, deque[0], deque[1]) > 0 ||
                cross(deque[deque.endIndex - 2], deque[deque.endIndex - 1], point) > 0
            else {
                continue
            }
            
            while cross(deque[deque.endIndex - 2], deque[deque.endIndex - 1], point) >= 0 {
                let _ = deque.popLast()
            }
            deque.append(point)
            
            while cross(point, deque[0], deque[1]) >= 0 {
                let _ = deque.popFirst()
            }
            deque.prepend(point)
        }
        
        return deque[..<(deque.endIndex - 1)].indices.map {
            (deque[$0], deque[$0 + 1])
        }
    }
}

fileprivate extension ContoursVision.Contour {
    static func rectangle<Rectangle: RectangleRepresentable>(
        _ type: Rectangle.Type = Rectangle.self,
        mapping points: [ SIMD2<Double> ],
        to edge: Edge,
        maximalArea: CGFloat
    ) -> (rectangle: Rectangle, area: CGFloat)? {
        // Make the edge as x axis, coordinate (M, N)
        let dX = edge.1.x - edge.0.x
        let dY = edge.1.y - edge.0.y
        let length = hypot(dX, dY)
        
        // Map points to (M, N)
        let (minM, maxM, minN) = points.reduce(
            into: (minM: Double.infinity, maxM: -Double.infinity, minN: Double.infinity)
        ) { results, point in
            let m = dot(edge.0, edge.1, point) / length
            results.minM = min(results.minM, m)
            results.maxM = max(results.maxM, m)
            
            let n = cross(edge.0, edge.1, point) / length
            if n < results.minN {
                results.minN = n
            }
        }
        
        // The max N is the edge
        let maxN = Double.zero
        
        let width = maxM - minM
        let height = maxN - minN
        
        let area: CGFloat = width * height
        guard area < maximalArea else {
            return nil
        }
        // TODO: Expand the rect here?
        
        let rectangle = Rectangle(
            topLeft: .init(
                x: edge.0.x + (minM * dX - maxN * dY) / length,
                y: edge.0.y + (minM * dY + maxN * dX) / length
            ),
            topRight: .init(
                x: edge.0.x + (maxM * dX - maxN * dY) / length,
                y: edge.0.y + (maxM * dY + maxN * dX) / length
            ),
            bottomRight: .init(
                x: edge.0.x + (maxM * dX - minN * dY) / length,
                y: edge.0.y + (maxM * dY + minN * dX) / length
            ),
            bottomLeft: .init(
                x: edge.0.x + (minM * dX - minN * dY) / length,
                y: edge.0.y + (minM * dY + minN * dX) / length
            )
        )
        
        // Find the real topLeft - topRight ...
        let normalized: Rectangle = switch atan2(dY, dX) / .pi {
        case -(3 / 4) ..< -(1 / 4):
            .init(
                topLeft: rectangle.bottomLeft,
                topRight: rectangle.topLeft,
                bottomRight: rectangle.topRight,
                bottomLeft: rectangle.bottomRight
            )
        case -(1 / 4) ..< (1 / 4): rectangle
        case (1 / 4) ..< (3 / 4):
            .init(
                topLeft: rectangle.topRight,
                topRight: rectangle.bottomRight,
                bottomRight: rectangle.bottomLeft,
                bottomLeft: rectangle.topLeft
            )
        default:
            .init(
                topLeft: rectangle.bottomRight,
                topRight: rectangle.bottomLeft,
                bottomRight: rectangle.topLeft,
                bottomLeft: rectangle.topRight
            )
        }
        
        return (normalized, area)
    }
}

fileprivate func cross(
    _ o: SIMD2<Double>,
    _ a: SIMD2<Double>,
    _ b: SIMD2<Double>
) -> Double {
    (a.x - o.x) * (b.y - o.y) -
    (a.y - o.y) * (b.x - o.x)
}

fileprivate func dot(
    _ o: SIMD2<Double>,
    _ a: SIMD2<Double>,
    _ b: SIMD2<Double>
) -> Double {
    (a.x - o.x) * (b.x - o.x) +
    (a.y - o.y) * (b.y - o.y)
}
