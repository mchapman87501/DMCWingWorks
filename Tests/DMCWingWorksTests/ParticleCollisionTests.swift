import DMC2D
import XCTest

@testable import DMCWingWorks

class ParticleCollisionTests: XCTestCase {
    // This is derived from a test case that shows a large change in (linear)
    // momentum in the C++ OpenMP wingworks implementation.
    func testFailingOpenMPScenario() throws {
        let p1 = Particle(
            s: Vector(x: 0.01, y: -0.01), v: Vector(x: 0.5, y: 0.5))
        let p2 = Particle(s: Vector(x: 0.0, y: 0.0), v: Vector(x: 0.5, y: -0.5))

        let mv0 = p1.momentum() + p2.momentum()

        XCTAssert(p1.isColliding(with: p2))

        p1.collide(with: p2)
        let mv = p1.momentum() + p2.momentum()
        let deltaMV = mv - mv0

        XCTAssertEqual(deltaMV, -0.414213, accuracy: 1.0e-6)

        p1.step()
        p2.step()
    }

    func testSelfCollision() throws {
        let s0 = Vector(x: 0.01, y: -0.01)
        let v0 = Vector(x: 0.5, y: 0.5)
        let p0 = Particle(s: s0, v: v0)

        p0.collide(with: p0)

        XCTAssertEqual(s0, p0.s)
        XCTAssertEqual(v0, p0.v)
    }
}
