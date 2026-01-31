//
//  Platform_Linux.swift
//  sgint
//
//  Created by Acrylic M. on 31.01.2026.
//

import Foundation

struct Platform_Linux: Platform_Desktop {
    var name: String { "linux" }
    var libExtension: String { "so" }
    var libPrefix: String { "lib" }
    
    func build(using builder: ExtensionBuilder) async throws -> String {
        return try await buildSwift(using: builder)
    }
}
