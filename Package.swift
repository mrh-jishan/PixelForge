// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PixelForge",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "PixelForge",
            targets: ["PixelForge"]
        )
    ],
    targets: [
        .executableTarget(
            name: "PixelForge",
            path: "Sources/PixelForge"
        )
    ]
)
