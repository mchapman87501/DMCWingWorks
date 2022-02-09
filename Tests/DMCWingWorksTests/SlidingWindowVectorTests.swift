//
//  SlidingWindowVectorTests.swift
//  DMCWingWorksTests
//
//  Created by Mitchell Chapman on 12/30/20.
//

import DMC2D
import XCTest

@testable import DMCWingWorks

class SlidingWindowVectorTests: XCTestCase {
    func testEmpty() throws {
        let vec = SlidingWindowVector()
        XCTAssertEqual(vec.value(), Vector())
    }

    func testConstant() throws {
        var vec = SlidingWindowVector()
        let constVal = Vector(x: 1.0, y: 1.0)

        for _ in 0..<50 {
            vec.add(constVal)
            XCTAssertEqual(vec.value(), constVal)
        }
    }
}
