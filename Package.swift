// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "HistoryClipboard",
    defaultLocalization: "zh-Hans",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "HistoryClipboard",
            targets: ["HistoryClipboard"]
        )
    ],
    targets: [
        .executableTarget(
            name: "HistoryClipboard",
            path: "Sources/HistoryClipboard"
        )
    ]
)
