// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Nabiz",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Nabiz",
            path: "Sources/Nabiz",
            linkerSettings: [.linkedFramework("IOKit")]
        )
    ]
)
