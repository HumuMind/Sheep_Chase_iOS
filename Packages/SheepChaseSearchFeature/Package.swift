// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SheepChaseSearchFeature",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "SheepChaseSearchFeature", targets: ["SheepChaseSearchFeature"])],
    dependencies: [
        .package(path: "../SheepChaseCore"),
        .package(path: "../SheepChasePersistence"),
        .package(path: "../SheepChaseRunStore"),
        .package(path: "../SheepChaseUI")
    ],
    targets: [
        .target(
            name: "SheepChaseSearchFeature",
            dependencies: [
                .product(name: "SheepChaseCore", package: "SheepChaseCore"),
                .product(name: "SheepChasePersistence", package: "SheepChasePersistence"),
                .product(name: "SheepChaseRunStore", package: "SheepChaseRunStore"),
                .product(name: "SheepChaseUI", package: "SheepChaseUI")
            ]
        ),
        .testTarget(name: "SheepChaseSearchFeatureTests", dependencies: ["SheepChaseSearchFeature"])
    ]
)
