// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "SheepChaseRunShellFeature",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "SheepChaseRunShellFeature", targets: ["SheepChaseRunShellFeature"])],
    dependencies: [
        .package(path: "../SheepChaseCore"),
        .package(path: "../SheepChasePersistence"),
        .package(path: "../SheepChaseRunStore"),
        .package(path: "../SheepChaseExport"),
        .package(path: "../SheepChaseUI"),
        .package(path: "../SheepChaseSceneFeature"),
        .package(path: "../SheepChaseBattleFeature"),
        .package(path: "../SheepChaseMapFeature"),
        .package(path: "../SheepChaseInspectorFeature"),
        .package(path: "../SheepChaseSearchFeature")
    ],
    targets: [
        .target(name: "SheepChaseRunShellFeature", dependencies: [
            .product(name: "SheepChaseCore", package: "SheepChaseCore"),
            .product(name: "SheepChasePersistence", package: "SheepChasePersistence"),
            .product(name: "SheepChaseRunStore", package: "SheepChaseRunStore"),
            .product(name: "SheepChaseExport", package: "SheepChaseExport"),
            .product(name: "SheepChaseUI", package: "SheepChaseUI"),
            .product(name: "SheepChaseSceneFeature", package: "SheepChaseSceneFeature"),
            .product(name: "SheepChaseBattleFeature", package: "SheepChaseBattleFeature"),
            .product(name: "SheepChaseMapFeature", package: "SheepChaseMapFeature"),
            .product(name: "SheepChaseInspectorFeature", package: "SheepChaseInspectorFeature"),
            .product(name: "SheepChaseSearchFeature", package: "SheepChaseSearchFeature")
        ]),
        .testTarget(name: "SheepChaseRunShellFeatureTests", dependencies: ["SheepChaseRunShellFeature", .product(name: "SheepChasePersistence", package: "SheepChasePersistence")])
    ]
)
