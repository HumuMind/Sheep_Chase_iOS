// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SheepChaseRunStore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "SheepChaseRunStore", targets: ["SheepChaseRunStore"])
    ],
    dependencies: [
        .package(path: "../SheepChaseCore"),
        .package(path: "../SheepChasePersistence"),
        .package(path: "../SheepChaseExport"),
        .package(path: "../SheepChaseBattleEngine")
    ],
    targets: [
        .target(
            name: "SheepChaseRunStore",
            dependencies: [
                .product(name: "SheepChaseCore", package: "SheepChaseCore"),
                .product(name: "SheepChasePersistence", package: "SheepChasePersistence"),
                .product(name: "SheepChaseExport", package: "SheepChaseExport"),
                .product(name: "SheepChaseBattleEngine", package: "SheepChaseBattleEngine")
            ]
        ),
        .testTarget(
            name: "SheepChaseRunStoreTests",
            dependencies: [
                "SheepChaseRunStore",
                .product(name: "SheepChaseCore", package: "SheepChaseCore"),
                .product(name: "SheepChasePersistence", package: "SheepChasePersistence")
            ]
        )
    ]
)
