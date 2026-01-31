//
//  Architecture.swift
//  sgint
//
//  Created by Acrylic M. on 30.01.2026.
//

import ArgumentParser
import Foundation

enum Architecture: String, CaseIterable, Codable, ExpressibleByArgument {
    case x86_64
    case aarch64
    
    var alias: String {
        switch self {
        case .x86_64:
            return self.rawValue
        case .aarch64:
            return "arm64"
        }
    }
    
    static var current: Architecture {
        get throws {
#if arch(arm64)
            return .aarch64
#elseif arch(x86_64)
            return .x86_64
#else
            throw ArchDetectionError.unsupportedArchitecture
#endif
        }
    }
    
    enum ArchDetectionError: Error {
        case unsupportedArchitecture
    }
}
