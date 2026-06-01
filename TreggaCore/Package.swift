// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TreggaCore",
    defaultLocalization: "es",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "TreggaCore",
            targets: ["TreggaCore"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/supabase-community/supabase-swift",
            from: "2.5.1"
        ),
        .package(
            url: "https://github.com/googlemaps/ios-maps-sdk",
            from: "10.13.0"
        ),
    ],
    targets: [
        .target(
            name: "TreggaCore",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Auth", package: "supabase-swift"),
                .product(name: "PostgREST", package: "supabase-swift"),
                .product(name: "Storage", package: "supabase-swift"),
                .product(name: "GoogleMaps", package: "ios-maps-sdk"),
            ],
            path: "Sources/TreggaCore",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "TreggaCoreTests",
            dependencies: ["TreggaCore"],
            path: "Tests/TreggaCoreTests"
        ),
    ]
)
