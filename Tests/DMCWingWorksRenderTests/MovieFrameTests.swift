import XCTest
@testable import DMCWingWorks
@testable import DMCWingWorksRender

class MovieFrameTests: XCTestCase {
    func testSingleFrame() throws {
        let foil = AirFoil(x: 0.0, y: 0.0, width: 15.0, alphaRad: 10.0 * .pi / 180.0)
        // Try for enough particle momentum to produce "visible" force on foil edges.
        let world = World(airfoil: foil, width: 30.0, height: 20.0, maxParticleSpeed: 0.01, windSpeed: 0.15)
        world.step()
        
        let framer = DMCWingWorksRender.MovieFrame(world: world, width: 1280, height: 720, title: "")
        let image = framer.createFrame()
        if let imageData = image.tiffRepresentation {
            let bitmapRep = NSBitmapImageRep(data: imageData)
            XCTAssertNotNil(bitmapRep)
        }
    }
}
