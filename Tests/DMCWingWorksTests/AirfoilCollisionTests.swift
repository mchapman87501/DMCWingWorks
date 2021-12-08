import XCTest

@testable import DMCWingWorks

import DMC2D

typealias Polygon = DMC2D.Polygon

class AirfoilCollisionTests: XCTestCase {

    func testCollision1() throws {
        let foil = AirFoil(x: 0.0, y: 0.0, width: 100.0, alphaRad: 0.0)
        let pos = Vector(foil.shape.vertices[0]) + Vector(x: 0.01, y: 0.0)
        let vel = Vector(x: 0.1, y: 0.0)
        let vUnit0 = vel.unit()
        let angle0 = atan2(vUnit0.y, vUnit0.x)
        let particle = Particle(s: pos, v: vel)

        let collider = AirFoilCollision(foil: foil)

        XCTAssertTrue(foil.shape.contains(point: CGPoint(particle.s)))
        let (edgeIndex, force) = collider.collide(particle: particle)
        XCTAssertNotNil(edgeIndex)
        XCTAssertNotNil(force)
        XCTAssertFalse(foil.shape.contains(point: CGPoint(particle.s)))
        let vUnitf = particle.v.unit()
        let anglef = atan2(vUnitf.y, vUnitf.x)
        XCTAssertNotEqual(angle0, anglef)
    }

    func vectorStr(_ v: Vector) -> String {
        let x = String(format: "%.3f", v.x)
        let y = String(format: "%.3f", v.y)
        return "[\(x), \(y)]"
    }

    func testCollideVertex(index i: Int) throws {
        let foil = AirFoil(x: 0.0, y: 0.0, width: 100.0, alphaRad: 0.0)
        let collider = AirFoilCollision(foil: foil)

        let vertex = foil.shape.vertices[i]
        // If a particle is coincident with a vertex, there is no normal
        // vector between them - thus, no way to figure out a recoil direction.
        let pos = Vector(vertex) + Vector(x: 0.01, y: 0.01)

        let vel = Vector(x: 0.1, y: 0.0)
        let particle = Particle(s: pos, v: vel)

        let vUnit0 = vel.unit()
        let angle0 = atan2(vUnit0.y, vUnit0.x)

        let (_, force) = collider.collide(particle: particle)

        XCTAssertNotNil(force)
        XCTAssertFalse(
            foil.shape.contains(point: CGPoint(particle.s)),
            "Collide vertex \(i): particle ended inside foil: \(vectorStr(pos)) -> \(vectorStr(particle.s))"
        )

        if let force = force, force.magnitude() > 0.0 {
            let vUnitf = particle.v.unit()
            let anglef = atan2(vUnitf.y, vUnitf.x)
            let angleMsg =
                "Collide vertex \(i): no Δ angle: \(vectorStr(pos)), \(vectorStr(vel)) -> \(vectorStr(particle.s)), \(vectorStr(particle.v))"
            XCTAssertNotEqual(angle0, anglef, angleMsg)
        }
    }

    func testCollideSelectedVertices() throws {
        for i in [10, 18, 25] {
            try testCollideVertex(index: i)
        }
    }

    func testCollideMidEdge(edgeIndex: Int) throws {
        let foil = AirFoil(x: 0.0, y: 0.0, width: 100.0, alphaRad: 0.0)
        let collider = AirFoilCollision(foil: foil)

        let edge = foil.shape.edges[edgeIndex]
        // Midpoint of the edge
        let xmid = Double(edge.p0.x + edge.pf.x) / 2.0
        let ymid = Double(edge.p0.y + edge.pf.y) / 2.0
        let pos = Vector(x: xmid, y: ymid)

        // Ensure the velocity vector points into the edge.
        let vel = Vector(x: 0.1, y: 0.0) + (
            foil.shape.edgeNormals[edgeIndex] * -0.01)
        let particle = Particle(s: pos, v: vel)

        let vUnit0 = vel.unit()
        let angle0 = atan2(vUnit0.y, vUnit0.x)

        let (_, force) = collider.collide(particle: particle)

        XCTAssertNotNil(force)
        XCTAssertTrue((force?.magnitude() ?? 0.0) > 0.0)
        if let force = force {
            print("Collision force: \(force)")
        }
        XCTAssertFalse(
            foil.shape.contains(point: CGPoint(particle.s)),
            "Edge \(edgeIndex): particle moved inside foil: \(pos) -> \(particle.s)"
        )
        let vUnitf = particle.v.unit()
        let anglef = atan2(vUnitf.y, vUnitf.x)
        let edgeStr =
            "Edge \(edgeIndex), \(vectorStr(Vector(edge.p0)))-\(vectorStr(Vector(edge.pf)))"
        let assertMsg =
            "\(edgeStr): no Δ angle: S: \(vectorStr(pos)), V: \(vectorStr(vel)) -> S: \(vectorStr(particle.s)), V: \(vectorStr(particle.v))"
        XCTAssertNotEqual(angle0, anglef, assertMsg)
    }

    // Verify expected collision results for particles 'blowing' into certain
    // airfoil edges
    func testCollideMid5() throws {
        try testCollideMidEdge(edgeIndex: 5)
    }

    func testCollideMid20() throws {
        try testCollideMidEdge(edgeIndex: 20)
    }

    func testCollideMid23() throws {
        try testCollideMidEdge(edgeIndex: 23)
    }

    // In simulations, the trailing top surface of the foil sometimes
    // recorded net negative normal force.  Two causes were found, as embodied
    // in these tests.

    // 1) Airfoil collision resolution sometimes completed with a particle
    // still inside the airfoil.

    func exampleFoilShape() -> Polygon {
        let vertexCoords: [(Double, Double)] = [
            (21.61566625583794, 30.582579917106106),
            (22.285935920085585, 31.40518764019059),
            (22.86876914734008, 31.675743426771763),
            (23.998393101103794, 31.98929160626099),
            (25.107325989624854, 32.17220154123417),
            (26.205579618665837, 32.28768528548939),
            (28.378058542917618, 32.36694384488441),
            (30.528511494491735, 32.307135885923635),
            (32.662945556845735, 32.14618864088592),
            (34.78403054484963, 31.90095865745075),
            (38.99282783498218, 31.199791844586784),
            (43.16958734667449, 30.296346459568934),
            (47.32498833940664, 29.25804869311516),
            (51.46036572061364, 28.09332681906521),
            (55.57905675888301, 26.823251522018445),
            (59.68172890793227, 25.45203693889474),
            (61.72605671842308, 24.722181209674225),
            (63.765712352891384, 23.9628265220146),
            (63.748358556236255, 23.85325896209791),
            (61.61792921618728, 24.039491028654865),
            (59.48816732985583, 24.22993723213169),
            (55.228643557192896, 24.61082963908534),
            (50.97178959939998, 25.008578593718475),
            (46.71627054904209, 25.41475582219136),
            (42.463421313554214, 25.837789598343736),
            (38.2185815226764, 26.31139301753458),
            (33.98308608384365, 26.843994353603644),
            (31.869343086732307, 27.135579843157412),
            (29.76160717307851, 27.46509256499003),
            (27.663215611469777, 27.853603203700867),
            (25.57950803164616, 28.3348248546489),
            (24.545329959485656, 28.62389825470145),
            (23.521831146805233, 28.980397845471963),
            (22.517688491932457, 29.459107406918783),
            (22.032303507433692, 29.803815610639006),
        ]
        return Polygon(vertexCoords)
    }

    func testMovedOutsideFoil() throws {
        let polygon = exampleFoilShape()
        let pos0 = Vector(x: 23.25846245734957, y: 30.378718758110857)
        let vel0 = Vector(x: 3.0, y: 0.0)
        let particle = Particle(s: pos0, v: vel0)

        let satpColl = SATPolyCollision(polygon: polygon)
        let collisionResult = satpColl.collisionNormal(particle)

        XCTAssertNotNil(collisionResult.overlap)
        if let overlap = collisionResult.overlap {
            XCTAssertEqual(overlap, 1.2738855345064835, accuracy: 1.0e-5)
        }

        // Is the particle outside after a collision?
        let collider = AirFoilCollision(
            foilShape: polygon, foilVel: Vector(x: 0.0, y: 0.0))
        let (_, force) = collider.collide(particle: particle)

        XCTAssertNotNil(force)

        let pos1 = particle.s
        let vel1 = particle.v
        XCTAssertTrue(polygon.contains(point: CGPoint(pos0)))
        XCTAssertFalse(polygon.contains(point: CGPoint(pos1)))
        XCTAssertNotEqual(vel0, vel1)
    }

    // 2) Collision resolution moved a particle outside the foil, with
    // a velocity away from the foil.  But the subsequent recoil force calculation
    // resulted in a recoil force, on the foil, that was directed away from the foil
    // edge.  In other words, it was effectively a "pull" on the foil rather than a
    // "push".

    // Parameterized test function:
    func testPositiveRecoilImpulse(particle: Particle, expectedEdgeIndex: Int?)
        throws
    {
        let polygon = exampleFoilShape()
        let pos0 = particle.s
        let vel0 = particle.v

        let collider = AirFoilCollision(
            foilShape: polygon, foilVel: Vector(x: 0.0, y: 0.0))
        let (edgeIndex, forceOnPolygon) = collider.collide(particle: particle)
        XCTAssertEqual(edgeIndex == nil, expectedEdgeIndex == nil)
        XCTAssertNotNil(forceOnPolygon)

        // Verify the force direction differs from the edge normal direction.
        if let index = expectedEdgeIndex {
            XCTAssertEqual(index, edgeIndex ?? -1)
            let edgeNormal = polygon.edgeNormals[index]
            if let forceOnPolygon = forceOnPolygon,
                forceOnPolygon.magnitude() > 0.0
            {
                let alongEdgeNormal = edgeNormal.dot(forceOnPolygon)
                XCTAssertTrue(alongEdgeNormal < 0.0)

                let normal2 = forceOnPolygon.dot(edgeNormal)
                XCTAssertEqual(alongEdgeNormal, normal2)
            }
        }

        let pos1 = particle.s
        XCTAssertNotEqual(pos0, pos1)

        let vel1 = particle.v
        // Verify that the particle's change in velocity
        // is away from the edge.
        let accel = vel1 - vel0
        XCTAssertTrue(accel.magnitude() >= 0.0)

        if accel.magnitude() > 0, let index = edgeIndex {
            let edgeNormal = polygon.edgeNormals[index]
            let alongNormal = edgeNormal.dot(accel)
            XCTAssertTrue(alongNormal >= 0.0)
        }

    }

    func testPositiveRecoilImpulse1() throws {
        let pos0 = Vector(x: 52.44017413168943, y: 27.889193305986247)
        let vel0 = Vector(x: 2.9852556164223527, y: 0.037031388844566804)
        let particle = Particle(s: pos0, v: vel0)
        try testPositiveRecoilImpulse(particle: particle, expectedEdgeIndex: 13)
    }

    func testPositiveRecoilImpulse2() throws {
        let pos0 = Vector(x: 36.94759769359838, y: 26.432684776816743)
        let vel0 = Vector(x: 3.0023826998695546, y: -0.023640365531086047)
        let particle = Particle(s: pos0, v: vel0)
        try testPositiveRecoilImpulse(particle: particle, expectedEdgeIndex: 25)
    }
}
