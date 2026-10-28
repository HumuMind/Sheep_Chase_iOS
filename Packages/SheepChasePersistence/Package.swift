// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SheepChasePersistence",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "SheepChasePersistence", targets: ["SheepChasePersistence"])
    ],
    dependencies: [
        .package(path: "../SheepChaseCore")
    ],
    targets: [
        .target(
            name: "SheepChasePersistence",
            dependencies: [.product(name: "SheepChaseCore", package: "SheepChaseCore")]
        ),
        .testTarget(
            name: "SheepChasePersistenceTests",
            dependencies: ["SheepChasePersistence", "SheepChaseCore"]
        )
    ]
)
