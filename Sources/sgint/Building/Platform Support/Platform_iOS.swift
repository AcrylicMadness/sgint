//
//  Platform_iOS.swift
//  sgint
//
//  Created by Acrylic M. on 30.01.2026.
//

import Foundation

protocol Platform_iOS: Platform {
    var desinationName: String { get }
}

extension Platform_iOS {
    var mainLibExtension: String { "framework" }
    var separateArchs: Bool { false }

    func build(
        using builder: ExtensionBuilder
    ) async throws -> String {
        let destination = "generic/platform=\(desinationName)"
        let driverPath = await builder.driverPath.path
        let archivePath = "\(driverPath)/xcodebuild.xcarchive"
        let buildModeName = await builder.buildMode.rawValue.capitalized
        
        if builder.fileSystem.fileExists(atPath: archivePath) {
            try builder.fileSystem.removeItem(atPath: archivePath)
        }
        // Build SwiftGodot driver as .xcarchive through xcbuild
        let command = [
            "cd \(driverPath)",
            "&&",
            "xcodebuild archive",
            "-scheme \(builder.driverName)",
            "-configuration \(buildModeName)",
            "-archivePath ./xcodebuild",
            "-destination '\(destination)'"
        ]
        
        try await builder.run(command.joined(separator: " "))
        
        return "\(driverPath)/xcodebuild.xcarchive/Products/usr/local/lib/"
        // TODO: Remove xcarchive and all build artifacts after
    }
}
