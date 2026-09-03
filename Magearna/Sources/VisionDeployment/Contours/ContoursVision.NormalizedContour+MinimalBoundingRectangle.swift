//
//  ContoursVision.NormalizedContour+MinimalBoundingRectangle.swift
//  Magearna
//
//  Created by Lucka on 2026-09-01.
//

import DequeModule
import Geometry
import Vision

public extension ContoursVision.NormalizedContour {
    func minimalBounding<Rectangle: RectangleRepresentable>(
        _ type: Rectangle.Type = Rectangle.self,
        in imageSize: CGSize,
        expandBy ratio: Double = 0
    ) -> Rectangle where Rectangle.Point == CGPoint {
        let edges = convexHullEdges(in: imageSize)
        let vertices = edges.map(\.0)
        
        var minimalArea = Double.infinity
        var minimalRectangle: Rectangle? = nil
        
        for edge in edges {
            guard
                let (rectangle, area) = Self.rectangle(
                    Rectangle.self,
                    mapping: vertices,
                    to: edge,
                    maximalArea: minimalArea,
                    expandBy: ratio
                )
            else {
                continue
            }
            
            minimalArea = area
            minimalRectangle = rectangle
        }
        
        // The image was flipped vertically, but the coordinate system of contour remains,
        // the "bottom" and "top" is in the opposite side
        return .init(
            topLeft: minimalRectangle!.bottomLeft,
            topRight: minimalRectangle!.bottomRight,
            bottomRight: minimalRectangle!.topRight,
            bottomLeft: minimalRectangle!.topLeft
        )
    }
}

fileprivate typealias CGEdge = (CGPoint, CGPoint)

fileprivate extension ContoursVision.NormalizedContour {
    func convexHullEdges(in imageSize: CGSize) -> [ CGEdge ] {
        // Reference: ON-LINE CONSTRUCTION OF THE CONVEX HULL OF A SIMPLE POLYLINE
        //            Avraham A. MELKMAN
        // https://www.ime.usp.br/~walterfm/cursos/mac0331/2006/melkman.pdf
        
        var deque = Deque<CGPoint>(minimumCapacity: points.count)
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
        
        if #available(macOS 15, *) {
            for index in deque.indices {
                deque[index] = NormalizedPoint(normalizedPoint: deque[index])
                    .toImageCoordinates(imageSize)
            }
        } else {
            let width = Int(imageSize.width)
            let height = Int(imageSize.height)
            
            for index in deque.indices {
                deque[index] = VNImagePointForNormalizedPoint(deque[index], width, height)
            }
        }
        
        return deque[..<(deque.endIndex - 1)].indices.map {
            (deque[$0], deque[$0 + 1])
        }
    }
}

fileprivate extension ContoursVision.NormalizedContour {
    static func rectangle<Rectangle: RectangleRepresentable>(
        _ type: Rectangle.Type = Rectangle.self,
        mapping points: [ CGPoint ],
        to edge: CGEdge,
        maximalArea: CGFloat,
        expandBy ratio: Double
    ) -> (rectangle: Rectangle, area: CGFloat)? {
        // Make the edge as x axis, coordinate (M, N)
        let dX = edge.1.x - edge.0.x
        let dY = edge.1.y - edge.0.y
        let length = hypot(dX, dY)
        
        // Map points to (M, N)
        var minM = Double.infinity
        var maxM = -Double.infinity
        var minN = Double.infinity
        for point in points {
            let m = dot(edge.0, edge.1, point) / length
            minM = min(minM, m)
            maxM = max(maxM, m)
            
            let n = cross(edge.0, edge.1, point) / length
            if n < minN {
                minN = n
            }
        }
        
        // The max N is the edge
        var maxN = Double.zero
        
        let width = maxM - minM
        let height = maxN - minN
        
        let area: CGFloat = width * height
        guard area < maximalArea else {
            return nil
        }
        
        let perimeter = (width + height) * 2
        let distance = area * ratio / perimeter
        
        maxM += distance
        minM -= distance
        maxN += distance
        minN -= distance
        
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
    _ o: CGPoint,
    _ a: CGPoint,
    _ b: CGPoint
) -> Double {
    (a.x - o.x) * (b.y - o.y) -
    (a.y - o.y) * (b.x - o.x)
}

fileprivate func dot(
    _ o: CGPoint,
    _ a: CGPoint,
    _ b: CGPoint
) -> Double {
    (a.x - o.x) * (b.x - o.x) +
    (a.y - o.y) * (b.y - o.y)
}
