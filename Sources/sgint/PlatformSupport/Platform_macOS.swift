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
    var driverLibPrefix: String { "lib" }
}
