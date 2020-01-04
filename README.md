# Playground

[![Swift 4.1](https://img.shields.io/badge/swift-4.1-orange.svg?style=flat)](#)
[![SwiftPM](https://img.shields.io/badge/swiftpm-compatible-brightgreen.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![@johnsundell](https://img.shields.io/badge/contact-@johnsundell-blue.svg?style=flat)](https://twitter.com/johnsundell)

Welcome to `playground`, a Swift script that enables you to super quickly generate Swift playgrounds from the command line - with or without dependencies - for any supported platform.

It essentially provides a command line interface to [Xgen](https://github.com/johnsundell/xgen).

**Features**

- [X] Generate playgrounds in seconds.
- [X] Automatically reuse any playground created today, for easy code note taking.
- [X] Add dependencies to a playground with a simple command - no more fiddling with workspaces.
- [X] Easily open a Gist or code from a GitHub URL in a playground.
- [X] Supports iOS, macOS & tvOS.

## Usage

**Simply run `playground` and a new playground will be created and opened**

```
$ playground
```

You can also supply various arguments to customize your playground:

**Add a playground at a specific path**

```
$ playground -t ~/MyPlayground
```

**Add some dependencies to your playground**

```
$ playground -d ~/unbox/unbox.xcodeproj,~/files/files.xcodeproj
```

**Open the contents of a Gist, a GitHub URL or any other URL in a playground**

```
$ playground -u https://gist.github.com/JohnSundell/b7f901e8edb89d1396ede4d8db3e8c21
```

**Quickly get started with view code prototyping**

```
$ playground -v
```

**Specify what platform you want the playground to run on**

```
$ playground -p tvOS
```

*For all available options, run `$ playground -h`*

## Installation

The easiest way to install `playground` is using the Swift Package Manager:

```
$ git clone https://github.com/JohnSundell/Playground.git
$ cd Playground
$ mv Sources/Playground.swift Sources/main.swift
$ swift build -c release
$ cp -f .build/release/Playground /usr/local/bin/playground
```

## Help, feedback or suggestions?

- [Open a PR](https://github.com/JohnSundell/Playground/pull/new/master) if you want to make some change to `playground`.
- Contact [@johnsundell on Twitter](https://twitter.com/johnsundell) for discussions, news & announcements about `playground` & other projects.
