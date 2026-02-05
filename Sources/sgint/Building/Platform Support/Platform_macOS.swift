//
//  Platform_macOS.swift
//  sgint
//
//  Created by Acrylic M. on 30.01.2026.
//

import Foundation

struct Platform_macOS: Platform_Desktop {
    var name: String { "macos" }
    var mainLibExtension: String { "dylib" }
    var libPrefix: String { "lib" }
    
    func build(
        using builder: ExtensionBuilder
    ) async throws -> String {
        return try await buildSwift(using: builder)
    }
}
