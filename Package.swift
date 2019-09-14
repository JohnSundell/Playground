// swift-tools-version:5.0

/**
 *  Playground
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import PackageDescription

// Package description
let package = Package(
    name: "Playground",
    platforms: [
        .macOS(.v10_10),
    ],
    products: [
        .executable(
            name: "playground",
            targets: ["Playground"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Files.git", from: "2.0.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
        .package(url: "https://github.com/JohnSundell/Xgen.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "Playground",
            dependencies: ["Files", "ShellOut", "Xgen"],
            path: "Sources",
            exclude: ["Marathonfile"]
        )
    ]
)
