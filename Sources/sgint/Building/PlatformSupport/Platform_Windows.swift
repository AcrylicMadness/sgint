//
//  Platform_Windows.swift
//  sgint
//
//  Created by Acrylic M. on 31.01.2026.
//

import Foundation

struct Platform_Windows: Platform_Desktop {
    var name: String { "windows" }
    var libExtension: String { "dll" }
    
    func build(using builder: ExtensionBuilder) async throws -> String {
        return try await buildSwift(using: builder)
    }
}
