// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "SheepChaseBattleFeature",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "SheepChaseBattleFeature", targets: ["SheepChaseBattleFeature"])],
    dependencies: [
        .package(path: "../SheepChaseCore"),
        .package(path: "../SheepChasePersistence"),
        .package(path: "../SheepChaseRunStore"),
        .package(path: "../SheepChaseUI")
    ],
    targets: [
        .target(name: "SheepChaseBattleFeature", dependencies: [
            .product(name: "SheepChaseCore", package: "SheepChaseCore"),
            .product(name: "SheepChasePersistence", package: "SheepChasePersistence"),
            .product(name: "SheepChaseRunStore", package: "SheepChaseRunStore"),
            .product(name: "SheepChaseUI", package: "SheepChaseUI")
        ]),
        .testTarget(name: "SheepChaseBattleFeatureTests", dependencies: ["SheepChaseBattleFeature", .product(name: "SheepChasePersistence", package: "SheepChasePersistence")])
    ]
)
