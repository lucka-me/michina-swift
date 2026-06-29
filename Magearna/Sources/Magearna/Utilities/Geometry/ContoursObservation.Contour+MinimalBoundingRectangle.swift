//
//  ContoursObservation.Contour+MinimalBoundingRectangle.swift
//  Magearna
//
//  Created by Lucka on 2026-06-28.
//

import DequeModule
import Vision

extension ContoursObservation.Contour {
    func minimalBoundingRectangle() -> RectangleObservation {
        let points = self.points
        let edges = Self.convexHullEdges(of: points)
        
        var minimalArea = Double.infinity
        var minimalRectangle: RectangleObservation? = nil
        for edge in edges {
            guard
                let (rectangle, area) = Self.rectangle(
                    mapping: points,
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

fileprivate typealias NormalizedEdge = [ 2 of NormalizedPoint ]

fileprivate extension ContoursObservation.Contour {
    static func convexHullEdges(
        of points: [ NormalizedPoint ]
    ) -> [ NormalizedEdge ] {
        // Reference: ON-LINE CONSTRUCTION OF THE CONVEX HULL OF A SIMPLE POLYLINE
        //            Avraham A. MELKMAN
        // https://www.ime.usp.br/~walterfm/cursos/mac0331/2006/melkman.pdf
        
        var deque = Deque<NormalizedPoint>(minimumCapacity: points.count)
        // Left > 0, Right < 0, opposite to the article
        if cross(points[0], points[1], points[2]) < 0 {
            deque.append(points[0])
            deque.append(points[1])
        } else {
            deque.append(points[1])
            deque.append(points[0])
        }
        deque.append(points[2])
        deque.prepend(points[2])
        
        for point in points[3...] {
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
            [ deque[$0], deque[$0 + 1] ]
        }
    }
    
    static func rectangle(
        mapping points: [ NormalizedPoint ],
        to edge: NormalizedEdge,
        maximalArea: CGFloat
    ) -> (rectangle: RectangleObservation, area: CGFloat)? {
        // Make the edge as x axis, coordinate (M, N)
        let dX = edge[1].x - edge[0].x
        let dY = edge[1].y - edge[0].y
        let length = hypot(dX, dY)
        
        // Map points to (M, N)
        let (minM, maxM, minN) = points.reduce(
            into: (minM: Double.infinity, maxM: -Double.infinity, minN: Double.infinity)
        ) { results, point in
            let m = dot(edge[0], edge[1], point) / length
            if m < results.minM {
                results.minM = m
            } else if m > results.maxM {
                results.maxM = m
            }
            let n = cross(edge[0], edge[1], point) / length
            if n < results.minN {
                results.minN = n
            }
        }
        
        // The max N is the edge
        let maxN = Double.zero
        let area: CGFloat = (maxM - minM) * (maxN - minN)
        guard area < maximalArea else {
            return nil
        }
        
        let rectangle = RectangleObservation(
            topLeft: .init(
                x: edge[0].x + (minM * dX - maxN * dY) / length,
                y: edge[0].y + (minM * dY + maxN * dX) / length
            ),
            topRight: .init(
                x: edge[0].x + (maxM * dX - maxN * dY) / length,
                y: edge[0].y + (maxM * dY + maxN * dX) / length
            ),
            bottomRight: .init(
                x: edge[0].x + (maxM * dX - minN * dY) / length,
                y: edge[0].y + (maxM * dY + minN * dX) / length
            ),
            bottomLeft: .init(
                x: edge[0].x + (minM * dX - minN * dY) / length,
                y: edge[0].y + (minM * dY + minN * dX) / length
            )
        )
        
        // Find the real topLeft - topRight ...
        let normalized: RectangleObservation = switch atan2(dY, dX) / .pi {
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
    _ o: NormalizedPoint,
    _ a: NormalizedPoint,
    _ b: NormalizedPoint
) -> Double {
    (a.x - o.x) * (b.y - o.y) -
    (a.y - o.y) * (b.x - o.x)
}

fileprivate func dot(
    _ o: NormalizedPoint,
    _ a: NormalizedPoint,
    _ b: NormalizedPoint
) -> Double {
    (a.x - o.x) * (b.x - o.x) +
    (a.y - o.y) * (b.y - o.y)
}
