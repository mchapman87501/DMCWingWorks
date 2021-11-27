/*
 struct AFCDiagnosticReporter {
    let polygon: Polygon
    let particle: Particle
    let pos0: Vector
    let vel0: Vector
    
    var cnr: SATPolyCollision.CollisionNormalResult? = nil
    
    init(polygon: Polygon, particle: Particle) {
        self.polygon = polygon
        self.particle = particle
        self.pos0 = particle.s
        self.vel0 = particle.v
    }
    
    mutating func recordCollisionNormal(_ result: SATPolyCollision.CollisionNormalResult) {
        cnr = result
    }

    func validate(collisionResult cr: AirFoilCollision.CollideResult) {
        // If the particle collided with an edge, make sure the recoil force, acting on
        // the airfoil, is in the opposite direction to the edge normal.
        // Or at least verify that it doesn't act along the edge normal.
        if let recoilForce = cr.force, recoilForce.magnitude() > 0.0 {
            if let cnr = cnr {
                if let edgeIndex = cnr.edgeIndex {
                    let edgeNormal = polygon.edgeNormals[edgeIndex]
                    let alongEdge = edgeNormal.dot(recoilForce)
                    if alongEdge > 0.0 {
                        reportCollisionDetails(recoilForce, edgeIndex, edgeNormal, alongEdge)
                    }
                }
            }
        }
    }
    
    private func vstr(_ v: Vector?) -> String {
        guard v != nil else { return "(-1.0, -1.0)" }
        return "(\(v!.x), \(v!.y))"
    }

    private func reportCollisionDetails(_ recoilForce: Vector, _ edgeIndex: Int, _ edgeNormal: Vector, _ alongEdge: Double) {
        let isNegVal = (alongEdge > 0.0) ? "True" : "False"
        let edge = polygon.edges[edgeIndex]
        let edgeX = (edge.p0.x, edge.pf.x)
        let edgeY = (edge.p0.y, edge.pf.y)
        print("""
plot_record(Record(
    particle_id=\(particle.id),
    mass=\(particle.mass),
    edge_index=\(edgeIndex),
    is_negative_force=\(isNegVal),
    recoil_force=\(vstr(recoilForce)),
    recoil_vec=\(vstr(cnr?.normal)),
    recoil_unit=\(vstr(cnr?.normal?.unit())),
    recoil_overlap=\(cnr?.overlap ?? -1.0),
    pos_before=\(vstr(pos0)),
    vel_before=\(vstr(vel0)),
    pos=\(vstr(particle.s)),
    vel=\(vstr(particle.v)),
    edge_x=\(edgeX),
    edge_y=\(edgeY),
    edge_normal=\(vstr(edgeNormal)),
    force_along_normal=\(alongEdge),
))
""")
    }
}
*/

struct AirFoilCollision {
    private let foilVel: Vector
    private let foilCollider: SATPolyCollision

    public init(foilShape: Polygon, foilVel: Vector) {
        self.foilVel = foilVel
        foilCollider = SATPolyCollision(polygon: foilShape)
    }

    public init(foil: AirFoil) {
        self.init(foilShape: foil.shape, foilVel: foil.v)
    }

    typealias CollideResult = (edgeIndex: Int?, force: Vector?)
    
    public func collide(particle: Particle) -> CollideResult {
//        var diag = AFCDiagnosticReporter(polygon: foilCollider.polygon, particle: particle)

        let collisionResult = foilCollider.collisionNormal(particle)
//        diag.recordCollisionNormal(collisionResult)

        if let recoilVec = collisionResult.normal {
            // Reminder: recoilForce is the force of the particle on the airfoil.
            let recoilForce = resolveCollision(particle: particle, recoilVec: recoilVec)
            let result = (edgeIndex: collisionResult.edgeIndex, force: recoilForce)
//            diag.validate(collisionResult: result)
            return result
        }
        return (nil, nil)
    }

    /// Resolve collision between the airfoil and a particle.
    /// Return the force vector of the particle on the airfoil.
    private func resolveCollision(particle: Particle, recoilVec: Vector) -> Vector {
        // This is not the right way to resolve the collision.
        // This just moves the particle to outside the airfoil.
        // More realistic might be to compute the past time, based on relative
        // velocities, at which the particle reached the surface of the airfoil;
        // to resolve the collision at that time point; and to integrate the particle's
        // new position at the current time based on its recoil velocity.
        
        // No real collision:
        if recoilVec.magSqr() <= 1.0e-6 {
            return Vector()
        }
        particle.s = particle.s.adding(recoilVec)
        let n = recoilVec.unit()
        // Treat the airfoil as being infinitely massive.
        let accelMag = calcAccelerationFromAirfoil(with: particle, n: n)
        let particleAccel = n.scaled(-accelMag)
        particle.v = particle.v.adding(particleAccel)
        
        return particleAccel.scaled(-particle.mass)
    }

    private func calcAccelerationFromAirfoil(with particle: Particle, n: Vector) -> Double {
        // e is the coefficient of restitution.  Set to 1 for
        // a perfectly elastic collision, I think.
        let e = 1.0
        // Relative collision velocity:
        let vr = foilVel.subtracting(particle.v)

        // A special case - or a bug?
        // Suppose the particle is already moving away from the foil.
        // Then its "collision" with the foil may be a logic error - or a
        // result of an integration error that placed the particle
        // too close to (or inside of) the foil.
        let vrdot = vr.dot(n)
        if vrdot < 0.0 {
            return 0.0
        }

        // Ignore rotational inertia.  Treat the airfoil as
        // being infinitely massive.
        let result = -(1.0 + e) * vrdot
        return result
    }
}
