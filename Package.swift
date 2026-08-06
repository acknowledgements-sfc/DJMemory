// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "DJMemory",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "djmemory", targets: ["DJMemoryCLI"]),
        .library(name: "DJMemoryCore", targets: ["DJMemoryCore"])
    ],
    targets: [
        .target(name: "DJMemoryCore"),
        .executableTarget(
            name: "DJMemoryCLI",
            dependencies: ["DJMemoryCore"]
        ),
        .testTarget(
            name: "DJMemoryCoreTests",
            dependencies: ["DJMemoryCore"]
        )
    ]
)
