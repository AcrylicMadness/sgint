//
//  GDExtension.swift
//  sgint
//
//  Created by Acrylic M. on 30.01.2026.
//

import Collections
import Foundation

/// A type representing GDExtension
struct GDExtension {
    
    /// GDExtension name
    let name: String
    
    /// Platforms supported by the extension
    let platforms: [any Platform]
    
    /// Architectures supported by the extension
    let archs: [Architecture]
    
    /// Configuration for the extension
    let configuration: Configuration
    
    /// Location of binaries for the extension
    let binLocation: String
    
    /// Build modes, debug and/or release
    let buildModes: [BuildMode]
    
    /// Dependency libraries for each platform that needs them, organazied by `(platform-id)-(arch)`
    let platformDependencies: [String: [String]]
    
    /// Runtime directory name
    let swiftRuntimeDir: String
    
    init(
        name: String,
        platforms: [any Platform],
        archs: [Architecture],
        configuration: Configuration = .standard,
        binLocation: String = "",
        buildModes: [BuildMode] = BuildMode.allCases,
        platformDependencies: [String: [String]],
        swiftRuntimeDir: String
    ) {
        self.name = name
        self.platforms = platforms
        self.archs = archs
        self.configuration = configuration
        self.binLocation = binLocation
        self.buildModes = buildModes
        self.platformDependencies = platformDependencies
        self.swiftRuntimeDir = swiftRuntimeDir
    }
    
    var tscnRepresentation: TSCN {
        var dependencies: TSCNValue = TSCNValue()
        var libraries: TSCNValue = TSCNValue()
        
        for mode in buildModes {
            for platform in platforms {
                if platform.separateArchs {
                    // TODO: Refactor this
                    for arch in archs {
                        // Different entries for different archs
                        let (
                            target,
                            driverLocation,
                            swiftGodotLocation
                        ) = tscnEntry(for: platform, in: mode, for: arch)
                        libraries[target] = driverLocation
                        var targetDependencies = [swiftGodotLocation: ""]
                        if let runtime = platformDependencies["\(platform.directory(for: arch))"] {
                            for libName in runtime {
                                let baseLocation = "\(platform.directory(for: arch))/\(mode.rawValue)"
                                targetDependencies["\(baseLocation)/\(libName)"] = ""
                            }
                        }
                        dependencies[target] = targetDependencies
                    }
                } else {
                    // A single entry, right now only for iOS / iOS Simulator
                    let (
                        target,
                        driverLocation,
                        swiftGodotLocation
                    ) = tscnEntry(for: platform, in: mode, for: nil)
                    libraries[target] = driverLocation
                    var targetDependencies = [swiftGodotLocation: ""]
                    if let runtime = platformDependencies[platform.directory(for: nil)] {
                        for libName in runtime {
                            let baseLocation = "\(platform.directory(for: nil))/\(mode.rawValue)"
                            targetDependencies["\(baseLocation)/\(libName)"] = ""
                        }
                    }
                    dependencies[target] = targetDependencies
                }
            }
        }
        return [
            "configuration": configuration.tscnValue,
            "libraries": libraries,
            "dependencies": dependencies
        ]
    }
    
    private
    func tscnEntry(
        for platform: any Platform,
        in mode: BuildMode,
        for arch: Architecture?
    ) -> (String, String, String) {
        var target = "\(platform.name).\(mode.rawValue)"
        if let arch {
            target += ".\(arch.alias)"
        }
        let (driverLib, swiftGodotLib) = platform.getMainLibNames(for: name)
        let baseLocation = "\(platform.directory(for: arch))/\(mode.rawValue)"
        let driverLocation = "\(baseLocation)/\(driverLib)"
        let swiftGodotLocation = "\(baseLocation)/\(swiftGodotLib)"
        return (target, driverLocation, swiftGodotLocation)
    }
    
    struct Configuration: Hashable, Codable {
        
        /// Name of entry fuction for the extension
        let entrySymbol: String
        
        /// Minimum supported Godot version
        let compatibilityMinimum: Double
        
        /// Maximum supported Godot version
        let compatibilityMaximum: Double?
        
        /// Can the extension be auto-reloaded upon recompilation.
        var reloadable: Bool?
        
        /// Is the extension a part of v2 Android plugin.
        var androidAarPlugin: Bool?
        
        var tscnValue: TSCNValue {
            get {
                Mirror(reflecting: self).children.reduce(
                    into: TSCNValue()
                ) { dict, element in
                    if
                        let label = element.label,
                        case Optional<any Codable & Hashable>.some(let value) = element.value
                    {
                        dict[label.toSnakeCase()] = value
                    }
                }
            }
        }
        
        static let standard: Configuration = .init(
            entrySymbol: "swift_entry_point",
            compatibilityMinimum: 4.2,
            compatibilityMaximum: nil,
            reloadable: nil,
            androidAarPlugin: nil
        )
    }
}
