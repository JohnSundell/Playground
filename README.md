# Playground

Welcome to `playground`, a Swift script that enables you to super quickly generate Swift playgrounds from the command line - with or without dependencies - for any supported platform.

Swift playgrounds are awesome for rapid prototyping, code note taking or just trying out something new or crazy. With `playground` you can get a playground up and running super quickly, and it takes all the hassle away when it comes to adding dependencies to a playground, making it easier than ever to try out new packages.

## Usage

Simply run `playground` on the command line, and a new playground will be created for you.

You can also supply various arguments to customize your playground:

**Add a playground at a specific path**

```
$ playground -t ~/MyPlayground
```

**Add some dependencies to your playground**

```
$ playground -d ~/unbox/unbox.xcodeproj,~/files/files.xcodeproj
```

**Specify what platform you want the playground to run on**

```
$ playground -p tvOS
```

*For all available options, run `$ playground -h`*

## Installation

The easiest way to install `playground` is using [Marathon](https://github.com/johnsundell/marathon):

```
$ marathon install https://raw.githubusercontent.com/JohnSundell/Playground/master/playground.swift
```

You can also install it manually by following these steps:

- Clone the repo: `$ git clone git@github.com:johnsundell/playground`.
- Make the script executable: `$ chmod +x playground/playground.swift`.
- Remove `.swift` from `playground.swift`.
- Move the `playground` file to `/usr/local/bin`.

## Help, feedback or suggestions?

- [Open an issue](https://github.com/JohnSundell/Playground/issues/new) if you need help, if you found a bug, or if you want to discuss a feature request.
- [Open a PR](https://github.com/JohnSundell/Playground/pull/new/master) if you want to make some change to `playground`.
- Contact [@johnsundell on Twitter](https://twitter.com/johnsundell) for discussions, news & announcements about `playground` & other projects.