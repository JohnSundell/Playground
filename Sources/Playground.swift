#!/usr/bin/swift

import Foundation
import Xgen
import Files
import ShellOut

// MARK: - Extensions

extension CommandLine {
    static var argumentsExcludingLaunchPath: [String] {
        var arguments = self.arguments
        arguments.removeFirst()
        return arguments
    }

    static func open(path: String) throws {
        print("🚀  Opening \(path)...")
        try shellOut(to: "open \(path)")
    }
}

extension Date {
    var today: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }
}

extension Playground {
    func apply(_ options: Options) {
        platform = options.platform

        if let newCode = options.code {
            code = newCode
        } else if options.addViewCode {
            let viewClass: String
            var viewCode: String

            switch platform {
            case .iOS, .tvOS:
                viewCode = "import UIKit"
                viewClass = "UIView"
            case .macOS:
                viewCode = "import Cocoa"
                viewClass = "NSView"
            }

            viewCode.append("\nimport PlaygroundSupport\n\n")
            viewCode.append("let viewFrame = CGRect(x: 0, y: 0, width: 500, height: 500)\n")
            viewCode.append("let view = \(viewClass)(frame: viewFrame)\n")
            viewCode.append("view.backgroundColor = .white\n")
            viewCode.append("PlaygroundPage.current.liveView = view\n")

            code = viewCode
        }
    }
}

// MARK: - Types

enum PlaygroundError: Error {
    case invalidFlag(String)
    case missingValue(Flag)
    case invalidPlatform(String)
    case invalidDependency(String)
}

extension PlaygroundError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidFlag(let flag):
            return "Invalid flag '\(flag)'. Run 'playground -h' for available options."
        case .missingValue(let flag):
            return "Missing value for flag '\(flag.rawValue)'."
        case .invalidPlatform(let platform):
            return "Invalid platform '\(platform)'. Must be iOS, macOS or tvOS."
        case .invalidDependency(let dependency):
            return "Invalid dependency '\(dependency)'. Make sure that it's an Xcode project that exists."
        }
    }
}

enum Flag: String {
    case targetPath = "-t"
    case platform = "-p"
    case dependencies = "-d"
    case code = "-c"
    case addViewCode = "-v"
    case forceOverwrite = "-f"
    case help = "-h"
}

struct Options {
    var targetPath = "~/Desktop/\(Date().today)"
    var platform = Playground.Platform.iOS
    var dependencies = [Folder]()
    var code: String? = nil
    var addViewCode = false
    var forceOverwrite = false
    var displayHelp = false

    init(arguments: [String] = CommandLine.argumentsExcludingLaunchPath) throws {
        var currentFlag: Flag?

        for argument in arguments {
            currentFlag = try parse(argument: argument, for: currentFlag)
        }

        if let danglingFlag = currentFlag {
            switch danglingFlag {
            case .targetPath, .platform, .dependencies, .code:
                throw PlaygroundError.missingValue(danglingFlag)
            case .forceOverwrite:
                forceOverwrite = true
            case .addViewCode:
                addViewCode = true
            case .help:
                displayHelp = true
            }
        }
    }

    private mutating func parse(argument: String, for currentFlag: Flag? = nil) throws -> Flag? {
        guard let flag = currentFlag else {
            guard let flag = Flag(rawValue: argument) else {
                throw PlaygroundError.invalidFlag(argument)
            }

            return flag
        }

        switch flag {
        case .targetPath:
            targetPath = argument
        case .platform:
            guard let parsedPlatform = Playground.Platform(rawValue: argument.lowercased()) else {
                throw PlaygroundError.invalidPlatform(argument)
            }

            platform = parsedPlatform
        case .dependencies:
            let paths = argument.components(separatedBy: ",")
            dependencies = try paths.map { path in
                do {
                    guard path.hasSuffix(".xcodeproj") else {
                        throw PlaygroundError.invalidDependency(path)
                    }

                    return try Folder(path: path)
                } catch {
                    throw PlaygroundError.invalidDependency(path)
                }
            }
        case .code:
            code = argument
        case .addViewCode:
            addViewCode = true
            return try parse(argument: argument)
        case .forceOverwrite:
            forceOverwrite = true
            return try parse(argument: argument)
        case .help:
            displayHelp = true
            return try parse(argument: argument)
        }

        return nil
    }
}

// MARK: - Functions

func displayHelp() {
    print("Playground")
    print("----------")
    print("Easily create Swift playgrounds from the command line")
    print("")
    print("Options:")
    print("")
    print("📁  -t   Specify a target path where the playground should be created")
    print("         Default: ~/Desktop/<Date>")
    print("📱  -p   Which platform (iOS, macOS or tvOS) that the playground should run on")
    print("         Default: iOS")
    print("📦  -d   Specify any Xcode projects that you wish to add as dependencies")
    print("         Should be a comma-separated list of file paths")
    print("📄  -c   Any code that you want to playground to contain")
    print("         Default: An empty playground that imports the system framework")
    print("🌄  -v   Fill the playground with the code required to prototype a view")
    print("         Default: Any code specified with -c or its default value")
    print("💪  -f   Force overwrite any existing playground at the target path")
    print("         Default: Don't overwrite, and instead open any existing playground")
    print("ℹ️  -h   Display this information")
}

// MARK: - Script

do {
    let options = try Options()

    guard !options.displayHelp else {
        displayHelp()
        exit(0)
    }

    func openIfNeeded(path: String) throws {
        guard !options.forceOverwrite else {
            return
        }

        guard (try? Folder(path: path)) != nil else {
            return
        }

        try CommandLine.open(path: path)
        exit(0)
    }

    if !options.dependencies.isEmpty {
        let workspace = Workspace(path: options.targetPath)
        try openIfNeeded(path: workspace.path)

        let playground = workspace.addPlayground()
        playground.apply(options)

        for dependency in options.dependencies {
            workspace.addProject(at: dependency.path)
        }

        try workspace.generate()

        print("✅  Generated Playground workspace at \(workspace.path)")
        try CommandLine.open(path: workspace.path)
    } else {
        let playground = Playground(path: options.targetPath)
        try openIfNeeded(path: playground.path)

        playground.apply(options)
        try playground.generate()

        print("✅  Generated Playground at \(playground.path)")
        try CommandLine.open(path: playground.path)
    }
} catch {
    print("💥  An error occured: \(error)")
}
