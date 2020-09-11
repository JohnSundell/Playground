#!/usr/bin/swift

import Foundation
import Cocoa
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
        let date = formatter.string(from: self)
        return date.replacingOccurrences(of: "/", with: "-")
    }
}

extension Playground {
    func apply(_ options: Options) throws {
        platform = options.platform
        autoRun = options.autoRun
        try options.code.map(add)
    }

    private func add(codeOption: Options.Code) throws {
        switch codeOption {
        case .view:
            addViewCode()
        case .fromClipboard:
            let pasteboard = NSPasteboard.general
            let copiedCode = pasteboard.string(forType: .string) ?? ""
            code = addFrameworkImportsIfNeeded(to: copiedCode)
        case .fromURL(let url):
            var loadedCode = try loadCode(from: url)

            if loadedCode.contains("import Cocoa") || loadedCode.contains("import AppKit") {
                platform = .macOS
            } else {
                loadedCode = addFrameworkImportsIfNeeded(to: loadedCode)
            }

            code = loadedCode
        case .custom(let customCode):
            code = customCode
        }
    }

    private func addViewCode() {
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

        switch platform {
        case .iOS, .tvOS:
            viewCode.append("view.backgroundColor = .white\n")
        case .macOS:
            viewCode.append("view.wantsLayer = true\n")
            viewCode.append("view.layer!.backgroundColor = NSColor.white.cgColor\n")
        }

        viewCode.append("PlaygroundPage.current.liveView = view\n")

        code = viewCode
    }

    private func loadCode(from url: URL) throws -> String {
        print("🌍  Downloading code from \(url)...")

        var url = url
        let urlString = url.absoluteString

        if urlString.contains("gist.github.com") {
            if !urlString.contains("/raw") {
                url = url.appendingPathComponent("raw")
            }
        } else if let gitHubRange = urlString.range(of: "github.com/") {
            let urlSuffix = urlString[gitHubRange.upperBound...]
            let rawURLSuffix = urlSuffix.replacingOccurrences(of: "/blob/", with: "/")
            url = URL(string: "https://raw.githubusercontent.com/" + rawURLSuffix)!
        }

        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw PlaygroundError.codeDownloadFailed(error)
        }
    }

    private func addFrameworkImportsIfNeeded(to code: String) -> String {
        var frameworks = ["Foundation", "PlaygroundSupport"]

        switch platform {
        case .iOS, .tvOS:
            frameworks.append("UIKit")
        case .macOS:
            frameworks.append("Cocoa")
        }

        let imports: [String] = frameworks.compactMap { framework in
            guard !code.contains(framework) else {
                return nil
            }

            return "import \(framework)"
        }

        guard !imports.isEmpty else {
            return code
        }

        return imports.joined(separator: "\n") + "\n\n" + code
    }
}

// MARK: - Types

enum PlaygroundError: Error {
    case invalidFlag(String)
    case missingValue(Flag)
    case invalidPlatform(String)
    case invalidDependency(String)
    case codeDownloadFailed(Error)
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
        case .codeDownloadFailed(let error):
            return "Failed to download code from the given URL. Underlying error: \(error)."
        }
    }
}

enum Flag: String {
    case targetPath = "-t"
    case platform = "-p"
    case dependencies = "-d"
    case code = "-c"
    case url = "-u"
    case addViewCode = "-v"
    case forceOverwrite = "-f"
    case autoRun = "-a"
    case help = "-h"
}

struct Options {
    var targetPath: String
    var platform = Playground.Platform.iOS
    var dependencies = [Folder]()
    var code: Code? = nil
    var forceOverwrite = false
    var autoRun = false
    var displayHelp = false

    init(arguments: [String] = CommandLine.argumentsExcludingLaunchPath) throws {
        let defaultTargetPath = FileManager.default.currentDirectoryPath + "/\(Date().today).playground"
        targetPath = defaultTargetPath

        var currentFlag: Flag?

        for argument in arguments {
            currentFlag = try parse(argument: argument, for: currentFlag)
        }

        if let danglingFlag = currentFlag {
            switch danglingFlag {
            case .targetPath, .platform, .dependencies, .url:
                throw PlaygroundError.missingValue(danglingFlag)
            case .forceOverwrite:
                forceOverwrite = true
            case .addViewCode:
                code = .view
            case .code:
                code = .fromClipboard
            case .autoRun:
                autoRun = true
            case .help:
                displayHelp = true
            }
        }

        if code != nil && (try? Folder(path: targetPath)) != nil {
            targetPath += "-\(UUID().uuidString)"
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
            if let folder = try? Folder(path: argument) {
                targetPath = folder.path + Date().today
            } else {
                targetPath = argument
            }
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
            guard !argument.hasPrefix("-") else {
                code = .fromClipboard
                return try parse(argument: argument)
            }

            code = .custom(argument)
        case .url:
            code = URL(string: argument).map(Code.fromURL)
        case .addViewCode:
            code = .view
            return try parse(argument: argument)
        case .forceOverwrite:
            forceOverwrite = true
            return try parse(argument: argument)
        case .autoRun:
            autoRun = true
            return try parse(argument: argument)
        case .help:
            displayHelp = true
            return try parse(argument: argument)
        }

        return nil
    }
}

extension Options {
    enum Code {
        case view
        case fromClipboard
        case fromURL(URL)
        case custom(String)
    }
}

// MARK: - Functions

func displayHelp() {
    print(
        """
        Playground
        ----------
        Easily create Swift playgrounds from the command line

        Options:

        📁  -t  Specify a target path where the playground should be created
                Default: <currentDirectoryPath>/<Date>
        📱  -p  Select platform (iOS, macOS or tvOS) that the playground should run on
                Default: iOS
        🏃‍♂️  -a  Turn on auto run for the generated playground
                Default: False
        📦  -d  Specify any Xcode projects that you wish to add as dependencies
                Should be a comma-separated list of file paths
        📄  -c  Any code that you want the playground to contain
                Pass this flag without a value to use the contents of your clipboard
                Default: An empty playground that imports the system framework
        🌍  -u  Any URL to code that you want the playground to contain
                Gist & GitHub links are automatically handled
        🌄  -v  Fill the playground with the code required to prototype a view
                Default: Any code specified with -c or its default value
        💪  -f  Force overwrite any existing playground at the target path
                Default: Don't overwrite, and instead open any existing playground
        ℹ️  -h  Display this information
        """
    )
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
        try playground.apply(options)

        for dependency in options.dependencies {
            workspace.addProject(at: dependency.path)
        }

        try workspace.generate()

        print("✅  Generated Playground workspace at \(workspace.path)")
        try CommandLine.open(path: workspace.path)
    } else {
        let playground = Playground(path: options.targetPath)
        try openIfNeeded(path: playground.path)

        try playground.apply(options)
        try playground.generate()

        print("✅  Generated Playground at \(playground.path)")
        try CommandLine.open(path: playground.path)
    }
} catch {
    print("💥  An error occured: \(error)")
}
