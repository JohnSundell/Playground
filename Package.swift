/**
 *  Playground
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import PackageDescription

// Copy the script into `main.swift` to build a command line tool
let scriptURL = URL(fileURLWithPath: "Sources/playground.swift")
let scriptData = try Data(contentsOf: scriptURL)

let mainURL = URL(fileURLWithPath: "Sources/main.swift")
try scriptData.write(to: mainURL)

// Package description
let package = Package(
    name: "Playground",
    dependencies: [
        .Package(url: "git@github.com:johnsundell/files.git", majorVersion: 1),
        .Package(url: "git@github.com:johnsundell/shellout.git", majorVersion: 1),
        .Package(url: "git@github.com:johnsundell/xgen.git", majorVersion: 1)
    ],
    exclude: ["Sources/Playground.swift"]
)
