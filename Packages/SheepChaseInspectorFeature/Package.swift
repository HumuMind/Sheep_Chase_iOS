// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "SheepChaseInspectorFeature",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "SheepChaseInspectorFeature", targets: ["SheepChaseInspectorFeature"])],
    dependencies: [
        .package(path: "../SheepChaseCore"),
        .package(path: "../SheepChasePersistence"),
        .package(path: "../SheepChaseRunStore"),
        .package(path: "../SheepChaseUI"),
        .package(path: "../SheepChaseBattleFeature")
    ],
    targets: [
        .target(name: "SheepChaseInspectorFeature", dependencies: [
            .product(name: "SheepChaseCore", package: "SheepChaseCore"),
            .product(name: "SheepChasePersistence", package: "SheepChasePersistence"),
            .product(name: "SheepChaseRunStore", package: "SheepChaseRunStore"),
            .product(name: "SheepChaseUI", package: "SheepChaseUI"),
            .product(name: "SheepChaseBattleFeature", package: "SheepChaseBattleFeature")
        ]),
        .testTarget(name: "SheepChaseInspectorFeatureTests", dependencies: ["SheepChaseInspectorFeature", .product(name: "SheepChasePersistence", package: "SheepChasePersistence")])
    ]
)
