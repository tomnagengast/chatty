// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Chatty",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Chatty", targets: ["ChattyApp"])
    ],
    targets: [
        .executableTarget(
            name: "ChattyApp",
            path: "Sources/ChattyApp"
        ),
        .testTarget(
            name: "ChattyAppTests",
            dependencies: ["ChattyApp"],
            path: "Tests/ChattyAppTests"
        )
    ]
)
