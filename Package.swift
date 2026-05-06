// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BarShelf",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "BarShelf", targets: ["BarShelf"])
    ],
    targets: [
        .executableTarget(
            name: "BarShelf",
            path: "Sources/BarShelf"
        )
    ]
)
