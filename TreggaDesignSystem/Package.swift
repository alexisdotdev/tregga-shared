// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TreggaDesignSystem",
    defaultLocalization: "es",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "TreggaDesignSystem",
            targets: ["TreggaDesignSystem"]
        ),
    ],
    targets: [
        .target(
            name: "TreggaDesignSystem",
            path: "Sources/TreggaDesignSystem",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "TreggaDesignSystemTests",
            dependencies: ["TreggaDesignSystem"],
            path: "Tests/TreggaDesignSystemTests"
        ),
    ]
)
