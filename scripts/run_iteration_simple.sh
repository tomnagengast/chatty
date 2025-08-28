#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "[iterate] Creating Package.swift for task 0..."

# Since claude CLI has issues with tools, let's directly implement task 0
# This is a one-time bootstrap to get Ralph working

cat > Package.swift << 'EOF'
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
            dependencies: ["ChattyApp"]
        )
    ]
)
EOF

echo "[iterate] Package.swift created successfully"

# Validate syntax
if swift package describe >/dev/null 2>&1; then
    echo "[validate] Package.swift syntax is valid"
    echo "true"
else
    echo "[validate] Package.swift syntax check failed"
    echo "false"
fi