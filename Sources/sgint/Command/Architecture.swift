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
}
