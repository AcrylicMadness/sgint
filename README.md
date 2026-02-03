# SwiftGodot Integrator (or sgint, for short) #

A simple cross-platform command line tool that building [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot)-based GDExtensions easier.
On Linux and Windows it will also embed Swift Runtime into extension and reference it in .gdextension file, which is necessary for the extension to function properly on these platforms.

Requires [Swift Toolchain](https://www.swift.org/install/).
iOS / iOS Simulator builds require Xcode Command Line Tools.

## Getting started ##

Use the following commands to clone and build sgint inside of current working directory.

On macOS and Linux:
```
curl -s https://raw.githubusercontent.com/AcrylicMadness/SwiftGodot-Integrator/refs/heads/main/setup.sh | bash
```
On Windows:
```
poweshell -Command Invoke-WebRequest -Uri https://raw.githubusercontent.com/AcrylicMadness/SwiftGodot-Integrator/refs/heads/main/setup.bat -OutFile "sgint-setup.bat"; ./sgint-setup.bat; DEL "sgint-setup.bat"
```
You can then move sgint into your /bin/ folder, or just put it into you game's root directory and use it from there.

## Usage ##

### Creating SwiftGodot extension ###

To create a new Swift-based GDExtension for your game, run following command from directory, containing `project.godot` for yor game:
```
sgint integrate
```
This will initialize a new Swift Package and configure it to work with SwiftGodot (add dependencies, set minimum target versions).
By default, name for the package will be inferred from current directory with '-Driver' suffix. You can use `-d, --driver-name <driver-name>` flag to customize the name.
```
sgint integrate -d CustomName
```

### Building ###

To build your Swift-based Godot extension, run:
```
sgint
```
This will build all the Swift code, move resulting libraries into /bin/ folder of your game and create a .gdextension file referencing them.
Use `-d, --driver-name <driver-name>` flag if you have a custom Swift Package name that sgint failed to infer:
```
sgint -d CustomName
```

On macOS, you can use `-t, --targets <targets>` flag to build for iOS or iOS Simulator as well (Requires Xcode Command Line Tools).
```
sgint -t macos -t ios
```
This command will build your extension for both macOS and iOS. Please note, that GDExtension format does not support referencing separate files for iOS and iOS Simulator, so using `sgint -p ios -p iossimulator` will fail.
