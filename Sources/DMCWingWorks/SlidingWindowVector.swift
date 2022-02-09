import DMC2D
import Foundation

/// Provides the average value of a vector over some number of recent samples.
///
/// It's hard to scale a particle simulation to a large enough number of particles so that the net force on
/// a shape, colliding with those particles, settles to a steady value.
///
/// `SlidingWindowVector` helps work
/// around this problem.  It records a sample of the net force at each time step, and it provides the running average over
/// the most recent samples.
public struct SlidingWindowVector {
    private let windowSize: Int
    private var values: [Vector]
    private var windowSum: Vector

    /// Create a new instance.
    /// - Parameter windowSize: the number of samples over which to average the vector
    public init(windowSize: Int = 30) {
        self.windowSize = windowSize
        values = [Vector]()
        windowSum = Vector()
    }

    /// Add a new sample.
    /// - Parameter value: a new value for the vector whose sliding window average is desired
    public mutating func add(_ value: Vector) {
        if values.count >= windowSize {
            let departing = values.removeFirst()
            windowSum -= departing
        }
        values.append(value)
        windowSum += value
    }

    /// Get the value of the vector, averaged over the most recent `windowSize` samples.
    /// - Returns: the sliding window average
    public func value() -> Vector {
        if values.count <= 0 {
            return Vector()
        }
        return windowSum / Double(values.count)
    }
}
