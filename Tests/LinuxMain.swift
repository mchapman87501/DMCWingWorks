import DMCWingWorksRenderTests
import DMCWingWorksTests
import XCTest

var tests = [XCTestCaseEntry]()
tests += DMCWingWorksTests.allTests()
tests += DMCWingWorksRenderTests.allTests()
XCTMain(tests)
