// swift-tools-version: 5.9
// This Package.swift is provided for reference and SPM compatibility.
// The primary build system is Xcode — open the .xcodeproj or create one via Xcode > File > New Project.

import PackageDescription

let package = Package(
    name: "GymClock",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "GymClockShared",
            targets: ["GymClockShared"]
        )
    ],
    targets: [
        .target(
            name: "GymClockShared",
            path: "Shared"
        )
    ]
)
