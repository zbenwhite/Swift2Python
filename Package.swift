// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Swift2Python",
    platforms: [
        .macOS(.v15),
        .iOS(.v16)
    ],
    products: [ .library(name: "Swift2Python", targets: ["Swift2Python"]), ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Swift2Python",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Collections", package: "swift-collections")
            ],
        ),
        .testTarget(
            name: "Swift2PythonTests",
            dependencies: ["Swift2Python"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
