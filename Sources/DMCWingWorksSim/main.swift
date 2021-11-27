import Foundation
import DMCWingWorks
import DMCWingWorksRender


func main() {
    let movieWidth = 1280
    let movieHeight = 720

    let worldWidth = Double(movieWidth) / 10.0
    let worldHeight = Double(movieHeight) / 10.0
    let alphaRad = 6.0 * .pi / 180.0
    let airfoil = AirFoil(
        x: 0.4 * worldWidth, y: 0.4 * worldHeight, width: worldWidth / 3.0, alphaRad: alphaRad)

    
    // Approximate ratio of random speed vs. wind speed, to mimic sea-level atmosphere at 20C
    // vs. an aircraft takeoff-ish speed near 36 m/s: 400:36
    let maxParticleSpeed = 400.0
    let windSpeed = 40.0
    let dsdtMax = 1.2
    let maxSpecifiedSpeed = max(maxParticleSpeed, windSpeed)
    let speedScale = dsdtMax / maxSpecifiedSpeed
    let scaledMaxPartSpeed = speedScale * maxParticleSpeed
    let scaledWindSpeed = speedScale * windSpeed

    let world = World(
        airfoil: airfoil, width: worldWidth, height: worldHeight, maxParticleSpeed: scaledMaxPartSpeed, windSpeed: scaledWindSpeed)

    let movieURL = URL(fileURLWithPath: "movie.mov")
    let title = """
Thermal Speed: \(maxParticleSpeed)
Wind Speed: \(windSpeed)
"""
    guard let writer = try? WorldWriter(
            world: world, writingTo: movieURL,
            width: movieWidth, height: movieHeight, title: title) else {
        print("Could not create world writer.")
        return
    }

    let seconds = 5
    let fps = 30
    
    try! writer.writeNextFrame()
    var index = 0
    var t0 = DispatchTime.now()
    for sec in 1...seconds {
        for iframe in 1...fps {
            world.step()
            index += 1

            try! writer.writeNextFrame()
            
            let tf = DispatchTime.now()
            let dt = Double(tf.uptimeNanoseconds - t0.uptimeNanoseconds) / 1.0e9

            print("\(sec).\(iframe)/\(seconds).\(fps): net mv \(world.netMomentum()); dt = \(dt) seconds")
            t0 = tf
        }
    }
    
    print("Summed force on foil: \(world.forceOnFoil())")
    try! writer.finish()
}

main()
