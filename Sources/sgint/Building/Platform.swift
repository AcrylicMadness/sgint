//
//  Platform.swift
//  sgint
//
//  Created by Acrylic M. on 30.01.2026.
//

import Foundation

protocol Platform: Hashable, Sendable {
    
    /// Platform name for use in .gdextension
    var name: String { get }
    
    /// Unique platform name
    var id: String { get }
    
    /// File extension for the main library that should be copied and referenced in .gdextension
    var mainLibExtension: String { get }
    
    /// File extensions for library files that should be copied, but not included in .gdextension
    var additionalLibExtensions: [String] { get }
    
    /// Prefix for library names
    var libPrefix: String { get }
    
    /// Name of SwiftGodot library file
    var swiftGodotLibName: String { get }
    
    /// Architectures supported by the platform
    var supportedArchs: [Architecture] { get }
    
    /// Determines if architectures should be separated in .gdextension file for this platform
    var separateArchs: Bool { get }
    
    /// Returns correct directory name for provided architecture
    /// - Parameter arch: Architectire (if applicable)
    /// - Returns: Directory Name
    func directory(for arch: Architecture?) -> String
    
    /// Returns complete names for main Swift Driver and SwiftGodot libraries
    /// (including prefix and file extension)
    /// - Parameter driverName: Swift Package name
    /// - Returns: Driver and SwiftGodot library names
    func getMainLibNames(
        for driverName: String
    ) -> (driverLib: String, swiftGodotLib: String)
    
    /// Returns complete names for additional library files
    /// (including prefix and file extension)
    /// - Parameter driverName: Swift Package name
    /// - Returns: Driver and SwiftGodot library names
    func getAdditionalLibNames(
        for driverName: String
    ) -> [(driverLib: String, swiftGodotLib: String)]
    
    /// Platform-specific build flow
    /// - Parameter builder: ExtensionBuilder
    /// - Returns: Path to the folder containing built library files
    func build(
        using builder: ExtensionBuilder
    ) async throws -> String
    
    func getRuntimeLibPath(
        using builder: ExtensionBuilder
    ) async throws -> String?
}

extension Platform {
    var libPrefix: String { "" }
    var separateArchs: Bool { true }
    var supportedArchs: [Architecture] { [.aarch64, .x86_64] }
    var id: String { name }
    var swiftGodotLibName: String { libPrefix + "SwiftGodot" }
    var additionalLibExtensions: [String] { [] }
    
    func directory(for arch: Architecture?) -> String {
        guard let arch, separateArchs else {
            return name
        }
        return "\(id)-\(arch.rawValue)"
    }
    
    func getMainLibNames(
        for driverName: String
    ) -> (driverLib: String, swiftGodotLib: String) {
        return (
            driverLib: "\(libPrefix)\(driverName).\(mainLibExtension)",
            swiftGodotLib: "\(swiftGodotLibName).\(mainLibExtension)"
        )
    }
    
    func getAdditionalLibNames(
        for driverName: String
    ) -> [(driverLib: String, swiftGodotLib: String)] {
        additionalLibExtensions.map { ext in
            (
                driverLib: "\(libPrefix)\(driverName).\(ext)",
                swiftGodotLib: "\(swiftGodotLibName).\(ext)"
            )
        }
    }
    
    func getRuntimeLibPath(
        using builder: ExtensionBuilder
    ) async throws -> String? {
        nil
    }
}
