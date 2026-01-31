//
//  Platform_Desktop.swift
//  sgint
//
//  Created by Acrylic M. on 31.01.2026.
//
import Foundation

protocol Platform_Desktop: Platform {
    func buildSwift(using builder: ExtensionBuilder) async throws -> String
}

extension Platform_Desktop {
        
    func buildSwift(using builder: ExtensionBuilder) async throws -> String {
        let archConfig = "--arch \(await builder.buildArch)"
        
        let cmd = await "cd \(builder.driverPath.path) && swift build \(archConfig) --configuration \(builder.buildMode)"
        try await builder.run(cmd)
        
        let binPath = try await builder.run(cmd + " --show-bin-path")
            .trimmingCharacters(in: CharacterSet.newlines)
        
        return binPath
    }
}
