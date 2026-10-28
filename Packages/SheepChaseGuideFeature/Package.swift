// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "SheepChaseGuideFeature",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "SheepChaseGuideFeature", targets: ["SheepChaseGuideFeature"])],
    dependencies: [
        .package(path: "../SheepChaseCore"),
        .package(path: "../SheepChaseUI")
    ],
    targets: [
        .target(name: "SheepChaseGuideFeature", dependencies: [
            .product(name: "SheepChaseCore", package: "SheepChaseCore"),
            .product(name: "SheepChaseUI", package: "SheepChaseUI")
        ]),
        .testTarget(name: "SheepChaseGuideFeatureTests", dependencies: ["SheepChaseGuideFeature"])
    ]
)
