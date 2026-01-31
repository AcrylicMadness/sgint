//
//  FileManager+Extensions.swift
//  sgint
//
//  Created by Acrylic M. on 30.01.2026.
//

import Foundation

#if os(macOS)
extension FileManager: @unchecked @retroactive Sendable { }
#endif
