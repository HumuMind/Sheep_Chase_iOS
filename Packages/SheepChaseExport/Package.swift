// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SheepChaseExport",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "SheepChaseExport", targets: ["SheepChaseExport"])
    ],
    dependencies: [
        .package(path: "../SheepChaseCore"),
        .package(path: "../SheepChasePersistence")
    ],
    targets: [
        .target(
            name: "SheepChaseExport",
            dependencies: [
                .product(name: "SheepChaseCore", package: "SheepChaseCore"),
                .product(name: "SheepChasePersistence", package: "SheepChasePersistence")
            ]
        ),
        .testTarget(
            name: "SheepChaseExportTests",
            dependencies: [
                "SheepChaseExport",
                .product(name: "SheepChaseCore", package: "SheepChaseCore"),
                .product(name: "SheepChasePersistence", package: "SheepChasePersistence")
            ]
        )
    ]
)
