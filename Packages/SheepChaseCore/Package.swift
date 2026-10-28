// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SheepChaseCore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "SheepChaseCore", targets: ["SheepChaseCore"])
    ],
    targets: [
        .target(name: "SheepChaseCore"),
        .testTarget(name: "SheepChaseCoreTests", dependencies: ["SheepChaseCore"])
    ]
)
