//
//  Platform.swift
//  sgint
//
//  Created by Acrylic M. on 30.01.2026.
//

import Foundation

protocol Platform: Hashable {
    var name: String { get }
    var libExtension: String { get }
    var swiftGodotLibName: String { get }
    var driverLibPrefix: String { get }
}

extension Platform {
    var swiftGodotLibName: String {
        driverLibPrefix + "SwiftGodot"
    }
    
    var driverLibPrefix: String {
        ""
    }
}
