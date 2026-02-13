// swift-tools-version: 6.0
// Shiori（栞）— 没入型読書アプリ
// Swift Package Manager 設定

import PackageDescription

let package = Package(
    name: "Shiori",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ShioriCore",
            targets: ["ShioriCore"]
        )
    ],
    dependencies: [
        // Firebase SDK（将来的に追加）
        // .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        // Google Mobile Ads（将来的に追加）
        // .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "11.0.0"),
    ],
    targets: [
        .target(
            name: "ShioriCore",
            dependencies: [],
            path: "Shiori",
            exclude: ["Info.plist"],
            sources: [
                "App",
                "Models",
                "ViewModels",
                "Views",
                "Services",
                "Engines",
                "Extensions",
                "Utilities"
            ]
        ),
        .testTarget(
            name: "ShioriTests",
            dependencies: ["ShioriCore"],
            path: "ShioriTests"
        )
    ]
)
