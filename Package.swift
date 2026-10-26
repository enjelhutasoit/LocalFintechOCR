// swift-tools-version:6.0
import PackageDescription

let strictConcurrency: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency")
]

let package = Package(
    name: "LocalFintechOCR",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(name: "LocalFintechOCR", targets: ["LocalFintechOCR"]),
        .library(name: "LocalFintechOCRCore", targets: ["LocalFintechOCRCore"]),
        .library(name: "LocalFintechOCRVision", targets: ["LocalFintechOCRVision"])
    ],
    targets: [
        .target(
            name: "LocalFintechOCRCore",
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "LocalFintechOCRVision",
            dependencies: ["LocalFintechOCRCore"],
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "LocalFintechOCR",
            dependencies: ["LocalFintechOCRCore", "LocalFintechOCRVision"],
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "LocalFintechOCRCoreTests",
            dependencies: ["LocalFintechOCRCore"]
        ),
        .testTarget(
            name: "LocalFintechOCRVisionTests",
            dependencies: ["LocalFintechOCRCore", "LocalFintechOCRVision"]
        ),
        .testTarget(
            name: "LocalFintechOCRTests",
            dependencies: ["LocalFintechOCR"]
        )
    ]
)
