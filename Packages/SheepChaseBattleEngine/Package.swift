// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SheepChaseBattleEngine",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "SheepChaseBattleEngine", targets: ["SheepChaseBattleEngine"])
    ],
    dependencies: [
        .package(path: "../SheepChaseCore")
    ],
    targets: [
        .target(
            name: "SheepChaseBattleEngine",
            dependencies: [.product(name: "SheepChaseCore", package: "SheepChaseCore")]
        ),
        .testTarget(
            name: "SheepChaseBattleEngineTests",
            dependencies: ["SheepChaseBattleEngine", .product(name: "SheepChaseCore", package: "SheepChaseCore")]
        )
    ]
)
