//
//  PolygonTests.swift
//  DMCWingWorksTests
//
//  Created by Mitchell Chapman on 3/5/20.
//

import XCTest
@testable import DMCWingWorks

struct PolyTestHelper {
    let poly: DMCWingWorks.Polygon
    
    func contains(_ x: Double, _ y: Double) -> Bool {
        poly.contains(point: CGPoint(x: x, y: y))
    }
}

class PolygonTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testBBox() throws {
        let poly = DMCWingWorks.Polygon([(0.0, 0.0), (10.0, 10.0), (0.0, 20.0), (-10.0, 10.0)])
        XCTAssertEqual(poly.bbox.origin.x, -10.0)
        XCTAssertEqual(poly.bbox.origin.y, 0.0)
        XCTAssertEqual(poly.bbox.size.width, 20.0)
        XCTAssertEqual(poly.bbox.size.height, 20.0)
    }

    func testContains1() throws {
        let poly = DMCWingWorks.Polygon([(0.0, 0.0), (10.0, 10.0), (0.0, 20.0), (-10.0, 10.0)])
        let pth = PolyTestHelper(poly: poly)
        
        // Crossing counts are fragile when the point lies near one of the
        // edge vertices
        XCTAssert(pth.contains(0.0, 0.01))
        XCTAssert(pth.contains(0.0, 10.0))
        XCTAssert(!pth.contains(-14.0, 10.0))
        XCTAssert(!pth.contains(0.0, 0.0))
        XCTAssert(!pth.contains(0.0, -0.01))
        XCTAssert(pth.contains(4.999, 5.0))
        XCTAssert(pth.contains(-5.0, 5.0))
    }
    
    func testContains2() throws {
        let foil = AirFoil(x: 0.0, y: 0.0, width: 100.0, alphaRad: 0.0)
        let shape = foil.shape
        let xvals = shape.vertices.map{ $0.x }
        let xmin = xvals.reduce(xvals[0]) { best, curr in (best < curr) ? best : curr }
        let xmax = xvals.reduce(xvals[0]) { best, curr in (best > curr) ? best : curr }
        
        let p0 = shape.vertices[0]
        // Hardwired knowledge: all of these points should be inside the foil shape, except the
        // first:
        let numSteps = 5
        let dx = (xmax - xmin) / CGFloat(numSteps)
        let y = p0.y
        for xOffset in 0..<numSteps {
            let x = p0.x + dx * CGFloat(xOffset)
            let p = CGPoint(x: x, y: y)
            let contains = foil.shape.contains(point: p)
            XCTAssertTrue(contains, "\(p)")
        }
    }

}
