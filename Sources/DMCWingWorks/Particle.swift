import Foundation

private class ParticleID {
    private static var _nextID = 0
    
    public static func nextID() -> Int {
        Self._nextID += 1
        return Self._nextID
    }
}

public class Particle {
    // Particles must be created by a single thread to ensure
    // their IDs are unique, and strictly ordered.
    let id: Int
    private let lock = DispatchSemaphore(value: 1)

    // All particles have the same size and mass
    static let commonRadius: Double = 0.125

    public let radius = Particle.commonRadius
    public let mass: Double = 1.0

    var s: Vector
    var v: Vector
    
    
    init() {
        id = ParticleID.nextID()
        s = Vector()
        v = Vector()
    }

    init(s sIn: Vector, v vIn: Vector) {
        id = ParticleID.nextID()
        s = sIn
        v = vIn
    }
    
    func reset(s sIn: Vector, v vIn: Vector) {
        s = sIn
        v = vIn
    }
    
    func momentum() -> Double {
        return mass * v.magnitude()
    }

    func isColliding(with other: Particle) -> Bool {
        let collisionDist = self.radius + other.radius
        return s.distSqr(other.s) <= (collisionDist * collisionDist)
    }

    /// Collide in a thread-safe way.
    func collide(with other: Particle) {
        if self === other {
            return;
        }
        let semas = (id < other.id) ? (lock, other.lock) : (other.lock, lock)
        semas.0.wait()
        semas.1.wait()
        let n = self.s.subtracting(other.s).unit()
        let jr = calcImpulse(with: other, n: n)
        let dv = n.scaled(-jr / self.mass)
        let otherDV = n.scaled(jr / other.mass)
        v = v.subtracting(dv)
        other.v = other.v.subtracting(otherDV)
        semas.1.signal()
        semas.0.signal()
    }

    private func calcImpulse(with other: Particle, n: Vector) -> Double {
        // e is the coefficient of restitution.  Set to 1 for
        // a perfectly elastic collision, I think.
        let e = 1.0
        // Relative collision velocity:
        let vr = v.subtracting(other.v)
        let numer = -(1.0 + e) * vr.dot(n)

        // Ignore rotational inertia
        let denom = 1.0 / mass + 1.0 / other.mass

        return numer / denom
    }
    
    /// Update the particle's position based on its velocity.
    func step() {
        s = s.adding(v)
    }
    
    public func pos() -> Vector {
        return s
    }
}

extension Particle: SATProjector {
    func projectedExtrema(unit vector: Vector) -> ProjExtrema {
        if vector.magSqr() <= 0.0 {
            return ProjExtrema(vMin: 0, vMax: 0)
        }

        let centerDot = s.dot(vector)
        return ProjExtrema(vMin: centerDot - radius, vMax: centerDot + radius)
    }
}
