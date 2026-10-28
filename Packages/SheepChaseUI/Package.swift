// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SheepChaseUI",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "SheepChaseUI", targets: ["SheepChaseUI"])
    ],
    dependencies: [
        .package(path: "../SheepChaseCore")
    ],
    targets: [
        .target(
            name: "SheepChaseUI",
            dependencies: [.product(name: "SheepChaseCore", package: "SheepChaseCore")],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SheepChaseUITests",
            dependencies: ["SheepChaseUI"]
        )
    ]
)
