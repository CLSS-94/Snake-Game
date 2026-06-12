// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SnakeGame",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "SnakeGameCore", targets: ["SnakeGameCore"])
    ],
    targets: [
        .target(name: "SnakeGameCore"),
        .testTarget(name: "SnakeGameCoreTests", dependencies: ["SnakeGameCore"])
    ]
)
