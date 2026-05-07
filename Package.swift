// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BarShelf",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "BarShelfCore", targets: ["BarShelfCore"]),
        .executable(name: "BarShelf", targets: ["BarShelf"])
    ],
    targets: [
        .target(
            name: "BarShelfCore",
            path: "Sources/BarShelfCore"
        ),
        .executableTarget(
            name: "BarShelf",
            dependencies: ["BarShelfCore"],
            path: "Sources/BarShelf"
        ),
        .testTarget(
            name: "BarShelfCoreTests",
            dependencies: ["BarShelfCore"],
            path: "Tests/BarShelfCoreTests"
        )
    ]
)
