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
    
    /// Configuration for the extension
    let configuration: Configuration
    
    /// Location of binaries for the extension
    let binLocation: String
    
    /// Build modes, debug and/or release
    let buildModes: [BuildMode]
    
    init(
        name: String,
        platforms: [any Platform],
        configuration: Configuration = .standard,
        binLocation: String = "res://bin",
        buildModes: [BuildMode] = BuildMode.allCases
    ) {
        self.name = name
        self.platforms = platforms
        self.configuration = configuration
        self.binLocation = binLocation
        self.buildModes = buildModes
    }
    
    var tscnRepresentation: TSCN {
        get throws {
            var dependencies: TSCNValue = TSCNValue()
            var libraries: TSCNValue = TSCNValue()
            
            for platform in platforms {
                for mode in buildModes {
                    let target = "\(platform.name).\(mode.rawValue)"
                    let driverLocation = "\(binLocation)/\(platform.driverLibPrefix)\(name).\(platform.libExtension)"
                    let swiftGodotLocation = "\(binLocation)/\(platform.swiftGodotLibName).\(platform.libExtension)"
                    dependencies[target] = driverLocation
                    libraries[target] = [swiftGodotLocation: ""]
                }
            }
            return [
                "configuration": configuration.tscnValue,
                "dependencies": dependencies,
                "libraries": libraries
            ]
        }
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
                        dict[label.camelCaseToSnakeCase()] = value
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
