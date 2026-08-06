// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SetCatcher",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "setcatcher", targets: ["SetCatcherCLI"]),
        .library(name: "SetCatcherCore", targets: ["SetCatcherCore"])
    ],
    targets: [
        .target(name: "SetCatcherCore"),
        .executableTarget(
            name: "SetCatcherCLI",
            dependencies: ["SetCatcherCore"]
        ),
        .testTarget(
            name: "SetCatcherCoreTests",
            dependencies: ["SetCatcherCore"]
        )
    ]
)
