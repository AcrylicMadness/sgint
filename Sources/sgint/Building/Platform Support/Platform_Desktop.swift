//
//  Platform_Desktop.swift
//  sgint
//
//  Created by Acrylic M. on 31.01.2026.
//
import Foundation

protocol Platform_Desktop: Platform {
    
    var debugInfoFormat: String? { get }
    
    func buildSwift(
        using builder: ExtensionBuilder
    ) async throws -> String
}

extension Platform_Desktop {
    
    var debugInfoFormat: String? { nil }
        
    func buildSwift(
        using builder: ExtensionBuilder
    ) async throws -> String {
        let archConfig = "--arch \(await builder.buildArch)"
        
        var commands = await [
            "cd \(builder.driverPath.path)",
            "&&",
            "swift build \(archConfig)",
            "--configuration \(builder.buildMode)"
        ]
        if let debugInfoFormat {
            commands.append("-debug-info-format \(debugInfoFormat)")
        }
        let cmd = commands.joined(separator: " ")
        try await builder.run(cmd)
        
        let binPath = try await builder.run(cmd + " --show-bin-path")
            .trimmingCharacters(in: CharacterSet.newlines)
        
        return binPath
    }
}
