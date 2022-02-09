import DMC2D
import Foundation

struct ProjExtrema {
    let vMin: Double
    let vMax: Double
}

protocol SATProjector {
    /// Get the minimum and maximum projection (dot products) of
    /// self along a unit vector.
    func projectedExtrema(unit vector: Vector) -> ProjExtrema
}

struct SATPolyCollision {
    let polygon: Polygon
    private let edgeNormals: [Vector]

    init(polygon polyIn: Polygon) {
        polygon = polyIn
        edgeNormals = polyIn.edgeNormals
    }

    private func overlapDistance(_ particle: Particle, along normal: Vector)
        -> Double
    {
        let p0 = polygon.projectedExtrema(unit: normal)
        let pf = particle.projectedExtrema(unit: normal)
        // If the minimum of one body is less than the maximum of the other,
        // then the overlap is the smaller of the min/max differences.  I think.
        // Need to draw a diagram to see whether this covers the case of one body
        // being completely within the other...
        //
        // Put another way: how far do you need to offset one body so the
        // two no longer overlap?
        let dist0 = pf.vMax - p0.vMin
        let dist1 = p0.vMax - pf.vMin
        let minDist = (dist0 < dist1) ? dist0 : dist1
        return (minDist <= 0.0) ? -1.0 : minDist
    }

    /// https://www.metanetsoftware.com/technique/tutorialA.html
    /// If the objects overlap along all of the possible separating axes, then they are definitely overlapping each other;
    /// we've found a collision, and this means we need to determine the **projection vector**, which will push the two objects apart.
    /// At this point, we've already done most of the work:
    /// each axis is a potential direction along which we can project the objects.
    /// So, all we need to do is find the axis with the smallest amount of overlap
    /// between the two objects, and we're done --
    /// the **direction** of the projection vector is the same as the axis direction,
    /// and the **length** of the projection vector is equal to the size of the overlap along that axis.

    typealias CollisionNormalResult = (
        edgeIndex: Int?, normal: Vector?, overlap: Double?
    )

    func collisionNormal(_ particle: Particle) -> CollisionNormalResult {
        let edgeResult = edgeCollisionNormal(particle)
        let vertResult = vertexCollisionNormal(particle)

        if let edgeOverlap = edgeResult.overlap {
            if let vertOverlap = vertResult.overlap {
                if edgeOverlap < vertOverlap {
                    return (
                        edgeResult.edgeIndex, edgeResult.normal,
                        edgeResult.overlap
                    )
                } else {
                    return (nil, vertResult.normal, vertResult.overlap)
                }
            }
        }
        return (nil, nil, nil)
    }

    private func edgeCollisionNormal(_ particle: Particle) -> (
        edgeIndex: Int?, normal: Vector?, overlap: Double?
    ) {
        var iNearest: Int?
        var displacementToNearest: Vector?
        var overlap: Double?

        for (i, normal) in edgeNormals.enumerated() {
            let currOverlap = overlapDistance(particle, along: normal)
            if currOverlap < 0.0 {
                return (nil, nil, nil)
            }

            if let bestOverlap = overlap {
                if currOverlap < bestOverlap {
                    overlap = currOverlap
                    iNearest = i
                    displacementToNearest = normal * currOverlap
                }
            } else {
                overlap = currOverlap
                iNearest = i
                displacementToNearest = normal * currOverlap
            }
        }
        return (
            edgeIndex: iNearest, normal: displacementToNearest, overlap: overlap
        )
    }

    private func vertexCollisionNormal(_ particle: Particle) -> (
        normal: Vector?, overlap: Double?
    ) {
        // Which polygon vertex is nearest the particle center?
        let vertNearest = polygon.nearestVertex(to: particle.s)
        let normal = (particle.s - vertNearest).unit()
        let overlap = overlapDistance(particle, along: normal)

        if overlap > 0.0 {
            return (normal: normal * overlap, overlap: overlap)
        }
        return (nil, nil)
    }
}

extension Polygon: SATProjector {
    func projectedExtrema(unit vector: Vector) -> ProjExtrema {
        var projections = Array(repeating: 0.0, count: vertices.count)
        for i in 0..<vertices.count {
            projections[i] = vertexVectors[i].dot(vector)
        }
        return ProjExtrema(
            vMin: projections.min() ?? 0.0, vMax: projections.max() ?? 0.0)
    }
}
