//
//  Platform_Windows.swift
//  sgint
//
//  Created by Acrylic M. on 31.01.2026.
//

import Foundation

struct Platform_Windows: Platform_Desktop {
    var name: String { "windows" }
    var mainLibExtension: String { "dll" }
    var debugInfoFormat: String? { "codeview" }
    // On Windows, we need to copy .pdp and .lib files as well
    var additionalLibExtension: [String] { ["pdp", "lib"] }
    
    func build(
        using builder: ExtensionBuilder
    ) async throws -> String {
        return try await buildSwift(using: builder)
    }

    func getSwiftRuntimePath(
        using builder: ExtensionBuilder
    ) async throws -> String? {
        // Get Swift version
        // Then get runtime from
        // %LocalAppData%\Programs\Swift\Runtimes\(version)\usr\bin
        // TODO: Figure dll locations dynamically

        let cmd = "swift -v"
        guard let swiftInfoString = try await builder
            .run(cmd)
            .split(separator: "\n")
            .first 
        else {
            return nil
        }
        let version = String(swiftInfoString
            .split(separator: " ")[2]
        )
        let runtimeDir = builder.fileSystem.homeDirectoryForCurrentUser
            .appendingPathComponent("AppData")
            .appendingPathComponent("Local")
            .appendingPathComponent("Programs")
            .appendingPathComponent("Swift")
            .appendingPathComponent("Runtimes")
            .appendingPathComponent(version)
            .appendingPathComponent("usr")
            .appendingPathComponent("bin")
            .path

        return runtimeDir
    }
}
