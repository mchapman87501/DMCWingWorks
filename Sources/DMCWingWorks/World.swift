import DMC2D
import Foundation
import GameplayKit

private let concurrency = ProcessInfo.processInfo.activeProcessorCount * 3

private func getUsableWorldArea(
    worldWidth width: Double, worldHeight height: Double, airfoil: AirFoil
) -> Double {
    let foilBB = airfoil.shape.bbox
    let foilApproxArea = Double(foilBB.width * foilBB.height)
    return (width * height) - foilApproxArea
}

private func getWorldDensity(
    worldWidth width: Double, worldHeight height: Double, airfoil: AirFoil,
    numParticles: Int
) -> Double {
    let area = getUsableWorldArea(
        worldWidth: width, worldHeight: height, airfoil: airfoil)
    return Double(numParticles) / area
}

class GaussRandom {
    static let gaussianSrc = GKRandomSource()
    // GameKit randoms seem to produce integer values. Convert to values in 0...1.
    static let gaussianDistro = GKGaussianDistribution(
        randomSource: gaussianSrc, lowestValue: -1_000_000_000,
        highestValue: 1_000_000_000)

    public static func rand() -> Double {
        Double(gaussianDistro.nextInt()) / 2_000_000_000.0
    }
}

struct Recycler {
    let worldWidth: Double
    let worldHeight: Double
    let airfoil: AirFoil

    let maxParticleSpeed: Double
    let windSpeed: Double

    func randomize(particles: [Particle]) {
        for p in particles {
            randomizeOne(particle: p)
        }
    }

    private func randomizeOne(particle: Particle) {
        randomizeOne(
            particle: particle, xMin: 0.0, yMin: 0.0, xMax: worldWidth,
            yMax: worldHeight)
    }

    private func randomizeOne(
        particle: Particle, xMin: Double, yMin: Double, xMax: Double,
        yMax: Double
    ) {
        var x = Double.random(in: (xMin...xMax))
        var y = Double.random(in: (yMin...yMax))
        while airfoil.shape.contains(x: x, y: y) {
            x = Double.random(in: (xMin...xMax))
            y = Double.random(in: (yMin...yMax))
        }
        let s = Vector(x: x, y: y)
        particle.reset(s: s, v: randomParticleVelocity())
    }

    private func randomParticleVelocity() -> Vector {
        let vWind = Vector(x: windSpeed, y: 0.0)
        // TODO *total* vector magnitude should not exceed maxParticleSpeed.
        let x = Double.random(in: (-1.0...1.0))
        let y = Double.random(in: (-1.0...1.0))
        let mag = GaussRandom.rand()
        let vRandom = Vector(x: x, y: y).unit() * mag
        return vRandom + vWind
    }

    func recycle(particles: [Particle]) {
        let offstageParticles = particles.filter { isOutOfWorld(particle: $0) }
        for particle in offstageParticles {
            recycleOne(particle: particle)
        }
    }

    private func recycleOne(particle: Particle) {
        // Not sure how to recycle given an environment in which the max random
        // particle speed is an order of magnitude > than the wind speed.
        let xOld = particle.s.x
        let yOld = particle.s.y

        func randWrap(_ vIn: Double, _ vMin: Double, _ vMax: Double) -> Double {
            let span = vMax - vMin
            var v = vIn
            while v < vMin {
                v += span
            }
            while v > vMax {
                v -= span
            }
            return v
        }

        if (0 > yOld) || (yOld > worldHeight) {
            // I give up: treat world y extrema as wind tunnel walls.
            let vNew = Vector(x: particle.v.x, y: -particle.v.y)
            particle.reset(s: particle.s, v: vNew)
            return
        }

        var x = randWrap(xOld, 0.0, worldWidth)
        var y = yOld

        while airfoil.shape.contains(x: x, y: y) {
            x = Double.random(in: (0...worldWidth))
            y = Double.random(in: (0...worldHeight))
        }
        let s = Vector(x: x, y: y)
        particle.reset(s: s, v: randomParticleVelocity())
    }

    private func estimatedDensity(of particles: [Particle]) -> Double {
        return getWorldDensity(
            worldWidth: worldWidth, worldHeight: worldHeight, airfoil: airfoil,
            numParticles: particles.count)
    }

    private func isOutOfWorld(particle: Particle) -> Bool {
        return isOutOfWorld(x: particle.s.x, y: particle.s.y)
    }

    private func isOutOfWorld(x: Double, y: Double) -> Bool {
        return ((x < 0.0) || (y < 0.0) || (x > worldWidth) || (y > worldHeight))
    }
}

/// Represents a world full of monoatomic gas particles and one lucky airfoil.
public class World {
    /// Airfoil with which particles interact
    public let airfoil: AirFoil

    /// World extent along x axis
    public let worldWidth: Double
    /// World extent along y axis
    public let worldHeight: Double

    let maxPartSpeed: Double
    let windSpeed: Double
    let numParticles: Int

    /// All of the particles in the world
    public private(set) var air: [Particle]

    var netForceOnFoil: SlidingWindowVector
    var edgeNormalForces: [SlidingWindowVector]

    private let cells: WorldCells

    let recycler: Recycler
    let foilCollider: AirFoilCollision

    private let queue = DispatchQueue(
        label: "UpdateQueue", qos: .utility, attributes: .concurrent)

    /// Create a new world.
    ///
    /// Both `maxParticleSpeed` and `windSpeed` should be scaled so that particles move roughly
    /// one world unit per ``step()``.  Otherwise particle-particle collisions may be missed, or particles may end up
    /// inside the airfoil, with incorrect collision resolution.
    /// - Parameters:
    ///   - foilIn: an airfoil with which particles will interact
    ///   - width: Extent of the world along the x axis
    ///   - height: Extent of the world along the y axis
    ///   - maxParticleSpeed: the maximum speed of any particle, in world extent units
    ///   - windSpeed: wind speed to be applied uniformly to all particles, in world extent units, in positive x direction
    public init(
        airfoil foilIn: AirFoil, width: Double, height: Double,
        maxParticleSpeed: Double, windSpeed: Double
    ) {
        airfoil = foilIn
        worldWidth = width
        worldHeight = height
        maxPartSpeed = maxParticleSpeed
        self.windSpeed = windSpeed

        let netWorldArea = getUsableWorldArea(
            worldWidth: width, worldHeight: height, airfoil: foilIn)

        let densityFudgeFactor = 3.0
        let diameter = 2.0 * Particle.commonRadius

        numParticles = Int(
            densityFudgeFactor * netWorldArea / (diameter * diameter))

        print("numParticles = \(numParticles)")

        // Legacy API: init takes in a windVel but uses only windVel.x.
        let cycler = Recycler(
            worldWidth: width, worldHeight: height,
            airfoil: foilIn,
            maxParticleSpeed: maxParticleSpeed, windSpeed: windSpeed)

        air = (0..<numParticles).map { _ in
            Particle()
        }
        cycler.randomize(particles: air)

        recycler = cycler
        foilCollider = AirFoilCollision(foil: foilIn)
        netForceOnFoil = SlidingWindowVector()
        edgeNormalForces = [SlidingWindowVector](
            repeating: SlidingWindowVector(), count: foilIn.shape.edges.count)

        cells = WorldCells(
            worldWidth: worldWidth, worldHeight: worldHeight,
            cellExtent: 2.0 * Particle.commonRadius, particles: air)
    }

    /// Collide particle with all particles in group.  Caller must ensure that part0 is not in group.
    private func collideParticleWithGroup(
        part0: Particle, cells: WorldCells, x: Int, y: Int
    ) {
        let (iStart, iEnd) = cells.cellStartEndIndices(x: x, y: y)
        if iStart < 0 {
            // This cell is empty.
            return
        }
        let pci = cells.particleCellIndex
        for i in iStart..<iEnd {
            let (_, iPart1) = pci[i]
            let part1 = air[iPart1]
            if part0.isColliding(with: part1) {
                part0.collide(with: part1)
            }
        }
    }

    /**
     * Resolve collisions involving all particles in cell [x, y].
     */
    private func collideGroup(cells: WorldCells, x: Int, y: Int) {
        let (iCenterStart, iCenterEnd) = cells.cellStartEndIndices(x: x, y: y)
        if iCenterStart < 0 {
            // This cell is empty.
            return
        }
        for i in iCenterStart..<iCenterEnd {
            // Collide the particle against all others in its neighborhood.
            // Collisions are symmetric.  How to avoid multiple collisions between
            // the same pairs of particles?
            // Colliding within a particle's cell: use upper-triangular collisions
            // Colliding with neighbor cells: same approach, but at the cell level.
            let (_, iPart0) = cells.particleCellIndex[i]
            let part0 = air[iPart0]
            for j in (i + 1)..<iCenterEnd {
                let (_, iPart1) = cells.particleCellIndex[j]
                let part1 = air[iPart1]
                if part0.isColliding(with: part1) {
                    part0.collide(with: part1)
                }
            }

            for (groupX, groupY) in [(x, y + 1), (x + 1, y), (x + 1, y + 1)] {
                if (groupX < cells.numH) && (groupY < cells.numV) {
                    collideParticleWithGroup(
                        part0: part0, cells: cells, x: groupX, y: groupY)
                }
            }
        }
    }

    private func collideParticles() {
        let group = DispatchGroup()
        // Make local copies of state that is needed inside async blocks:
        let cells = self.cells
        let collideGroup = self.collideGroup

        let yMax = cells.numV
        let xMax = cells.numH
        let chunkSize = max(1, yMax / concurrency)
        for yStart in stride(from: 0, to: yMax, by: chunkSize) {
            queue.async(group: group) {
                let yEnd = min(yStart + chunkSize, yMax)
                for y in yStart..<yEnd {
                    for x in 0..<xMax {
                        collideGroup(cells, x, y)
                    }
                }
            }
        }
        group.wait()
    }

    private func integrate() {
        let group = DispatchGroup()
        let iMax = air.count
        let chunkSize = max(1, iMax / concurrency)
        for i in stride(from: 0, to: iMax, by: chunkSize) {
            queue.async(group: group) { [weak self] in
                let iNext = i + chunkSize
                let jMax = (iNext < iMax) ? iNext : iMax
                let air = self!.air
                for j in i..<jMax {
                    let particle = air[j]
                    particle.step()
                }
            }
        }
        group.wait()
        recycler.recycle(particles: air)
    }

    /// Calculate one simulation step.
    ///
    /// Collide particles with each other and with the airfoil, and update their positions.
    public func step() {
        cells.update(particles: air)
        collideParticles()
        collideWithFoil()
        integrate()
    }
}

// Airfoil-particle collision processing:
extension World {
    /// Get the net force on the airfoil due to particle interactions.
    ///
    /// The returned value is a running average over the most recent time steps.
    /// - Returns: the net force on the airfoil
    public func forceOnFoil() -> Vector { return netForceOnFoil.value() }

    /// Get the net force on each airfoil shape segment due to particle interactions.
    ///
    /// As with ``forceOnFoil()``, this method returns running average forces.
    ///
    /// - Returns: an array of net force vectors, one for each airfoil shape segment
    public func foilEdgeForces() -> [Vector] {
        return edgeNormalForces.map { $0.value() }
    }

    private func collideWithFoil() {
        let forces = calcFoilCollisions()
        netForceOnFoil.add(forces.netForce)
        let numEdges = edgeNormalForces.count
        for i in 0..<numEdges {
            edgeNormalForces[i].add(forces.edgeForces[i])
        }
    }

    private func calcFoilCollisions() -> (
        netForce: Vector, edgeForces: [Vector]
    ) {
        var netForce = Vector()
        let numEdges = airfoil.shape.edges.count
        var edgeForces = [Vector](repeating: Vector(), count: numEdges)

        let resultQueue = DispatchQueue(label: "sum foil force")
        let group = DispatchGroup()
        let iMax = air.count
        let chunkSize = max(1, iMax / concurrency)
        let air = self.air
        let collide = foilCollider.collide
        for i in stride(from: 0, to: iMax, by: chunkSize) {
            queue.async(group: group) {
                let iNext = i + chunkSize
                let jMax = (iNext < iMax) ? iNext : iMax
                var chunkNF = Vector()
                var chunkEFs = [Vector](repeating: Vector(), count: numEdges)
                for j in i..<jMax {
                    let collResult = collide(air[j])
                    if let impulseVec = collResult.force {
                        chunkNF += impulseVec
                        if let iEdge = collResult.edgeIndex {
                            chunkEFs[iEdge] += impulseVec
                        }
                    }
                }
                resultQueue.async(group: group) {
                    netForce = netForce + chunkNF
                    for i in 0..<numEdges {
                        edgeForces[i] += chunkEFs[i]
                    }
                }
            }
        }
        group.wait()
        return (netForce, edgeForces)
    }

    /// Get the total momentum of all world particles.
    /// - Returns: the total momentum
    public func netMomentum() -> Double {
        return air.reduce(0.0) { partial, curr in
            partial + curr.momentum()
        }
    }
}
