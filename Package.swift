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
        .library(name: "LocalFintechOCRCore", targets: ["LocalFintechOCRCore"])
    ],
    targets: [
        .target(
            name: "LocalFintechOCRCore",
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "LocalFintechOCR",
            dependencies: ["LocalFintechOCRCore"],
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "LocalFintechOCRCoreTests",
            dependencies: ["LocalFintechOCRCore"]
        ),
        .testTarget(
            name: "LocalFintechOCRTests",
            dependencies: ["LocalFintechOCR"]
        )
    ]
)
