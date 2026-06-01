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
    dependencies: [
        .package(url: "https://github.com/isapozhnik/hugeicons-swift.git", from: "4.1.6"),
    ],
    targets: [
        .target(
            name: "TreggaDesignSystem",
            dependencies: [
                .product(name: "Hugeicons", package: "hugeicons-swift"),
            ],
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
