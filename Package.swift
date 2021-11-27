// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DMCWingWorks",
    // https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html
    platforms: [
        .macOS(.v11),
        //.linux
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "DMCWingWorks",
            targets: ["DMCWingWorks"]),
        .library(
            name: "DMCWingWorksRender",
            targets: ["DMCWingWorksRender"]),
        .executable(
            name: "DMCWingWorksSim",
            targets: ["DMCWingWorksSim"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/mchapman87501/DMCMovieWriter.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "DMCWingWorks",
            dependencies: []),
        .target(
            name: "DMCWingWorksRender",
            dependencies: ["DMCMovieWriter", "DMCWingWorks"]),
        .target(
            name: "DMCWingWorksSim",
            dependencies: ["DMCWingWorksRender", "DMCWingWorks"]),
        .testTarget(
            name: "DMCWingWorksTests",
            dependencies: ["DMCWingWorks"]),
        .testTarget(
            name: "DMCWingWorksRenderTests",
            dependencies: ["DMCWingWorksRender"]),
    ]
)
