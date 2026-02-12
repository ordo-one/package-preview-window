// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "package-preview-window",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "PreviewWindow",
            targets: ["PreviewWindow"]
        ),
    ],
    targets: [
        .target(
            name: "PreviewWindow",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
