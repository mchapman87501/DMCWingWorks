import Foundation

public struct Vector: Equatable {
    public let x: Double
    public let y: Double

    public init(x xIn: Double, y yIn: Double) {
        x = xIn
        y = yIn
    }

    public func subtracting(_ other: Vector) -> Vector {
        return Vector(x: self.x - other.x, y: self.y - other.y)
    }
    
    public func adding(_ offset: Vector) -> Vector {
        return Vector(x: offset.x + self.x, y: offset.y + self.y)
    }

    public func dot(_ other: Vector) -> Double {
        return (x * other.x) + (y * other.y)
    }

    public func magSqr() -> Double {
        return x * x + y * y
    }
    
    public func distSqr(_ other: Vector) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return dx * dx + dy * dy
    }

    public func magnitude() -> Double {
        return sqrt(magSqr())
    }

    public func unit() -> Vector {
        let m = magnitude()
        if m <= 0 {
            return Vector(x: 0.0, y: 0.0)
        }
        return Vector(x: self.x / m, y: self.y / m)
    }

    public func normal() -> Vector {
        Vector(x: -self.y, y: self.x)
    }

    public func scaled(_ s: Double) -> Vector {
        return Vector(x: self.x * s, y: self.y * s)
    }
    
    public func angle() -> Double {
        return atan2(self.y, self.x)
    }
}

extension Vector {
    init() {
        x = 0
        y = 0
    }

    init(_ p: CGPoint) {
        self.init(x: Double(p.x), y: Double(p.y))
    }
}

extension CGPoint {
    init(_ v: Vector) {
        self.init(x: v.x, y: v.y)
    }
}
