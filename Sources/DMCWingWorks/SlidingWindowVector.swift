//
//  SlidingWindowVector.swift
//  DMCWingWorks
//
//  Created by Mitchell Chapman on 12/18/20.
//

import Foundation

/// A  sliding window vector averages values of a vector – e.g., a force vector calculated from
/// instantaneous impulses – over time intervals – e.g., the last N samples.
public struct SlidingWindowVector {
    private let windowSize: Int
    private var values: [Vector]
    private var windowSum: Vector

    public init(windowSize wsIn: Int = 30) {
        windowSize = wsIn
        values = [Vector]()
        windowSum = Vector()
    }

    public mutating func add(_ value: Vector) {
        if values.count >= windowSize {
            let departing = values.removeFirst()
            windowSum = windowSum.subtracting(departing)
        }
        values.append(value)
        windowSum = windowSum.adding(value)
    }

    public func value() -> Vector {
        if values.count <= 0 {
            return Vector()
        }
        return windowSum.scaled(1.0 / Double(values.count))
    }
}
