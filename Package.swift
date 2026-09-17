// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LiquidLevel",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(name: "LiquidLevel", targets: ["LiquidLevel"]),
    ],
    targets: [
        .target(name: "LiquidLevel"),
        .testTarget(name: "LiquidLevelTests", dependencies: ["LiquidLevel"]),
    ]
)
