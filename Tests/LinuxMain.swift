import XCTest

import DMCWingWorksTests
import DMCWingWorksRenderTests

var tests = [XCTestCaseEntry]()
tests += DMCWingWorksTests.allTests()
tests += DMCWingWorksRenderTests.allTests()
XCTMain(tests)
