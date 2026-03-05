// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "package-preview-window",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
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
