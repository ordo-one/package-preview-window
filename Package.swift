// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "package-preview-window",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
    ],
    products: [
        .library(
            name: "PreviewWindowChrome",
            targets: ["PreviewWindowChrome"]
        ),
    ],
    targets: [
        .target(
            name: "PreviewWindowChrome"
        ),
    ]
)
