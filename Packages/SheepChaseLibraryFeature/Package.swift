// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SheepChaseLibraryFeature",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "SheepChaseLibraryFeature", targets: ["SheepChaseLibraryFeature"])],
    dependencies: [
        .package(path: "../SheepChaseCore"),
        .package(path: "../SheepChasePersistence"),
        .package(path: "../SheepChaseRunStore"),
        .package(path: "../SheepChaseUI"),
        .package(path: "../SheepChaseSearchFeature")
    ],
    targets: [
        .target(
            name: "SheepChaseLibraryFeature",
            dependencies: [
                .product(name: "SheepChaseCore", package: "SheepChaseCore"),
                .product(name: "SheepChasePersistence", package: "SheepChasePersistence"),
                .product(name: "SheepChaseRunStore", package: "SheepChaseRunStore"),
                .product(name: "SheepChaseUI", package: "SheepChaseUI"),
                .product(name: "SheepChaseSearchFeature", package: "SheepChaseSearchFeature")
            ]
        ),
        .testTarget(name: "SheepChaseLibraryFeatureTests", dependencies: ["SheepChaseLibraryFeature"])
    ]
)
