//
//  Platform_macOS.swift
//  sgint
//
//  Created by Acrylic M. on 30.01.2026.
//

import Foundation

struct Platform_macOS: Platform {
    var name: String { "macos" }
    var libExtension: String { "dylib" }
    var libPrefix: String { "lib" }
    
    func build(using builder: Builder) async throws {
        let archConfig = await builder.buildArchs.reduce(into: "") { partialResult, arch in
            partialResult.append("--arch \(arch) ")
        }
        
        let cmd = await "cd \(builder.driverPath.path) && swift build \(archConfig)--configuration \(builder.buildMode)"
        try await builder.run(cmd)
        
        let binPath = try await builder.run(cmd + " --show-bin-path")
            .trimmingCharacters(in: CharacterSet.newlines)
        
        guard let libraries = Array<String>(
            mirrorChildValuesOf: (
                getLibNames(for: builder.driverName)
            )
        ) else {
            throw Builder.BuildError.failedToMapBinariesPaths
        }
        
        // TODO: Move copying logic into builder
        for library in libraries {
            print("Copying \(library)")
            
            let originUrl = URL(fileURLWithPath: binPath)
                .appendingPathComponent(library)
            
            let destinationDirectoryUrl = await builder
                .workingDirectory
                .appendingPathComponent(builder.binFolderName)
                .appendingPathComponent(builder.driverName)
                .appendingPathComponent(name)
                .appendingPathComponent(builder.buildMode.rawValue)
            
            
            if !builder.fileManager.fileExists(atPath: destinationDirectoryUrl.path) {
                try builder.fileManager.createDirectory(
                    at: destinationDirectoryUrl,
                    withIntermediateDirectories: true,
                    attributes: nil)
            }
            
            let destinationUrl = destinationDirectoryUrl
                .appendingPathComponent(library)

            if builder.fileManager.fileExists(atPath: destinationUrl.path) {
                try builder.fileManager.removeItem(atPath: destinationUrl.path)
            }
            
            try builder.fileManager.copyItem(at: originUrl, to: destinationUrl)
        }
    }
}
