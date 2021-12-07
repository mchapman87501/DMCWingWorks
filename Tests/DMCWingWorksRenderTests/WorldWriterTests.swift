//
//  WorldWriterTests.swift
//  simulate_libTests
//
//  Created by Mitchell Chapman on 12/30/20.
//

import XCTest

@testable import DMCWingWorks
@testable import DMCWingWorksRender

class WorldWriterTests: XCTestCase {
    let movieURL = URL(fileURLWithPath: "movie.mov")

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: movieURL.path) {
            try fm.removeItem(at: movieURL)
        }
    }

    func testWorldWriter() throws {
        let foil = AirFoil(
            x: 0.0, y: 0.0, width: 5.0, alphaRad: 10.0 * .pi / 180.0)
        // Try for enough particle momentum to produce "visible" force on foil edges.
        let world = World(
            airfoil: foil, width: 8.0, height: 6.0, maxParticleSpeed: 0.01,
            windSpeed: 0.15)

        let movieWidth = 320
        let movieHeight = 240
        guard
            let writer = try? WorldWriter(
                world: world, writingTo: movieURL,
                width: movieWidth, height: movieHeight)
        else {
            XCTFail("Could not create world writer.")
            return
        }

        try writer.showTitle("Your Title Here")

        for _ in 0..<32 {
            world.step()
            try writer.writeNextFrame()
        }

        let frameWidth = Double(movieWidth) / 2.0
        let frameHeight = Double(movieHeight) / 2.0
        let frameImage = writer.getNextFrame(width: frameWidth)
        XCTAssertEqual(frameImage.size.width, frameWidth)
        XCTAssertEqual(frameImage.size.height, frameHeight)

        try writer.finish()
        let moviePath = movieURL.path
        let fm = FileManager.default
        XCTAssert(
            fm.fileExists(atPath: moviePath), "No such file: \(moviePath)")

        let attrs = try fm.attributesOfItem(atPath: moviePath)
        let fileSize = attrs[.size]! as! Int
        XCTAssertTrue(fileSize > 0)
    }
}
