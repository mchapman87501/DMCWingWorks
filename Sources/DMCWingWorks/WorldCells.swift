import Foundation

private let concurrency = ProcessInfo.processInfo.activeProcessorCount * 3

/**
 * Partlcles will only ever interact with other particles that are close to them.
 * Divide the world into regions, and let each region be processed independently
 * of the others -- perhaps in a separate thread.
 * Assign particles to regions based on their current positions
 * Each particle may be assigned to one or more regions.  A particle near the
 * boundary of a region could interact with particles on the other side of the boundary.
 */
typealias Cell = [Particle]

class WorldCells {
    let worldWidth: Double
    let worldHeight: Double
    let cellExtent: Double
    
    let numH: Int
    let numV: Int
    let numCells: Int
    
    private(set) var particleCellIndex: [(Int, Int)]
    private var cellStart: [Int]
    private var cellEnd: [Int]
    
    init(worldWidth wwIn: Double, worldHeight whIn: Double, cellExtent ceIn: Double, particles: [Particle]) {
        worldWidth = wwIn
        worldHeight = whIn
        cellExtent = ceIn
        
        numH = Int(ceil(wwIn / ceIn))
        numV = Int(ceil(whIn / ceIn))
        numCells = numH * numV
        particleCellIndex = [(Int, Int)](repeating: (0, 0), count: particles.count)
        cellStart = [Int](repeating: -1, count: numCells)
        cellEnd = [Int](repeating: -1, count: numCells)
        
        update(particles: particles)
    }
    
    public func update(particles: [Particle]) {
        for i in 0..<particles.count {
            let p = particles[i]
            let x = max(0.0, min(worldWidth, p.s.x))
            let y = max(0.0, min(worldHeight, p.s.y))
            
            let iCellRow = min(numV - 1, Int(y / cellExtent))
            let iCellCol = min(numH - 1, Int(x / cellExtent))
            let cellIndex = iCellRow * numH + iCellCol
            particleCellIndex[i] = (cellIndex, i)
        }
        particleCellIndex.sort { (entry1, entry2) in
            let (i1, ip1) = entry1
            let (i2, ip2) = entry2
            if i1 < i2 {
                return true
            }
            if i1 == i2 {
                return ip1 < ip2
            }
            return false
        }

        // A cell start/end index < 0 means the cell contains no particles.
        for i in 0..<cellStart.count {
            cellStart[i] = -1
            cellEnd[i] = -1
        }
        
        var prevCellIndex = -1
        for i in 0..<particleCellIndex.count {
            let (cellIndex, _) = particleCellIndex[i]
            if (i == 0) || (cellIndex != prevCellIndex) {
                cellStart[cellIndex] = i
                if prevCellIndex >= 0 {
                    cellEnd[prevCellIndex] = i
                }
                prevCellIndex = cellIndex
            }
        }
        // What is the cell end of the last cellIndex?
        if prevCellIndex >= 0 {
            cellEnd[prevCellIndex] = particleCellIndex.count
        }
    }
    
    public func cellIndex(x xCell: Int, y yCell: Int) -> Int {
        return yCell * numH + xCell
    }
    
    public func cellStartEndIndices(x: Int, y: Int) -> (Int, Int) {
        let offset = cellIndex(x: x, y: y)
        return (cellStart[offset], cellEnd[offset])
    }
}
