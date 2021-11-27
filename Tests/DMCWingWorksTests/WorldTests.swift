//
//  WorldTests.swift
//  DMCWingWorksTests
//
//  Created by Mitchell Chapman on 12/30/20.
//

import XCTest

@testable import DMCWingWorks

class WorldTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testWorldIterate() throws {
        let foil = AirFoil(x: 0.0, y: 0.0, width: 5.0, alphaRad: 0.0)
        let world = World(
            airfoil: foil, width: 10.0, height: 7.0, maxParticleSpeed: 0.01,
            windSpeed: 0.0)

        XCTAssertTrue(world.air.count > 0)
        for _ in 0..<3 {
            world.step()
        }
        XCTAssertTrue(world.netMomentum() >= 0)
        XCTAssertEqual(world.foilEdgeForces().count, foil.shape.edges.count)
        // Weak test:  There should be *some* random force on the foil.
        XCTAssertTrue(world.netForceOnFoil.value().magSqr() > 0.0)
    }

    //    func testPerformanceExample() throws {
    //        // This is an example of a performance test case.
    //        self.measure {
    //            // Put the code you want to measure the time of here.
    //        }
    //    }

}
