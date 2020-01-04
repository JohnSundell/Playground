// swift-tools-version:5.1

/**
 *  Playground
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import PackageDescription

let package = Package(
    name: "Playground",
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Files.git", from: "2.0.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
        .package(url: "https://github.com/JohnSundell/Xgen.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "Playground",
            dependencies: ["Files", "ShellOut", "Xgen"]
        )
    ]
)
