import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        return [
            testCase(AirfoilCollisionTests.allTests),
            testCase(ParticleCollisionTests.allTests),
            testCase(PolygonTests.allTests),
            testCase(SlidingWindowTests.allTests),
            testCase(VectorTests.allTests),
            testCase(WorldTests.allTests),
        ]
    }
#endif
