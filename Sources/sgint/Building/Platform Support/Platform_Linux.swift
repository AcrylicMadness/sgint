//
//  Platform_Linux.swift
//  sgint
//
//  Created by Acrylic M. on 31.01.2026.
//

import Foundation

struct Platform_Linux: Platform_Desktop {
    var name: String { "linux" }
    var mainLibExtension: String { "so" }
    var libPrefix: String { "lib" }
    
    func build(
        using builder: ExtensionBuilder
    ) async throws -> String {
        return try await buildSwift(using: builder)
    }
    
    func getSwiftRuntimePath(
        using builder: ExtensionBuilder
    ) async throws -> String? {
        // Run ldd on copied libSwiftGodot.so
        // Look for libFoundation.so
        // Get its directory
        let outputDir = await builder.binDestinationDirectory(
            for: self,
            with: builder.buildArch
        )
        let swiftGodotPath = outputDir
            .appendingPathComponent("\(swiftGodotLibName).\(mainLibExtension)")
            .path
        
        let command = "ldd \(swiftGodotPath)"
        let links = try await builder
            .run(command)
            .split(separator: "\n")
        
        guard let libFoundationLink = links.first(
            where: { $0.contains("libFoundation.so") }
        ) else {
            print("Unable to find libFoundation.so in ldd output")
            return nil
        }
        // Extract absoulte path from ldd output, which looks something like this
        // library_name.so.x => /absolute/path/to/library_file (0x00007f...)
        let libFoundationPath = libFoundationLink
            .split(separator: " ")[2]
            .split(separator: "/")
            .dropLast()
            .joined(separator: "/")
            
        return "/\(libFoundationPath)"
    }
}
