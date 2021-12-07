import XCTest
@testable import DMCWingWorks
@testable import DMCWingWorksRender

class MovieFrameTests: XCTestCase {
    func testSingleFrame() throws {
        let foil = AirFoil(x: 0.0, y: 0.0, width: 15.0, alphaRad: 10.0 * .pi / 180.0)
        // Try for enough particle momentum to produce "visible" force on foil edges.
        let world = World(airfoil: foil, width: 30.0, height: 20.0, maxParticleSpeed: 0.01, windSpeed: 0.15)
        
        let framer = DMCWingWorksRender.MovieFrame(world: world, width: 1280, height: 720, title: "")
        let image = framer.createFrame()
        if let imageData = image.tiffRepresentation {
            let bitmapRep = NSBitmapImageRep(data: imageData)
            XCTAssertNotNil(bitmapRep)
        }
        world.step()
        let framer2 = DMCWingWorksRender.MovieFrame(world: world, width: 1280, height: 720, title: "After 1 Step")
        let image2 = framer2.createFrame()
        if let imageData2 = image2.tiffRepresentation {
            let bitmapRep = NSBitmapImageRep(data: imageData2)
            XCTAssertNotNil(bitmapRep)
        }
    }
}
