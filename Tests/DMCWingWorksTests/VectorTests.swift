//
//  VectorTests.swift
//  DMCWingWorksTests
//
//  Created by Mitchell Chapman on 12/30/20.
//

import XCTest
@testable import DMCWingWorks

class VectorTests: XCTestCase {

    func testZeroUnit() throws {
        let zeroUnit = Vector().unit()
        XCTAssertEqual(zeroUnit.magnitude(), 0.0)
    }
}
