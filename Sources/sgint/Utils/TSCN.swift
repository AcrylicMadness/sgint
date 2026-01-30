//
//  TSCN.swift
//  sgint
//
//  Created by Acrylic M. on 30.01.2026.
//

import Collections
import Foundation

/// Set of key-value pairs that can be used in TSCN headings or sections
typealias TSCNValue = OrderedDictionary<String, any Codable & Hashable>

/// Container for TSCN type
typealias TSCN = OrderedDictionary<TSCNHeading, TSCNValue>

/// TSCN Header
struct TSCNHeading: Hashable, ExpressibleByStringLiteral {
    let name: String
    let properties: TSCNValue
    
    init(stringLiteral value: StringLiteralType) {
        self.init(name: value)
    }

    init(
        name: String,
        properties: TSCNValue = [:]
    ) {
        self.name = name
        self.properties = properties
    }

    static func == (
        lhs: TSCNHeading,
        rhs: TSCNHeading
    ) -> Bool {
        guard lhs.name == rhs.name else { return false }
        guard lhs.properties.count == rhs.properties.count else { return false }
        for (key, lValue) in lhs.properties {
            guard let rValue = rhs.properties[key] else { return false }
            if AnyHashable(lValue) != AnyHashable(rValue) { return false }
        }
        return true
    }

    func hash(
        into hasher: inout Hasher
    ) {
        hasher.combine(name)
        // Sorting keys to ensure deterministic hashing
        for key in properties.keys.sorted() {
            hasher.combine(key)
            if let value = properties[key] {
                hasher.combine(AnyHashable(value))
            }
        }
    }
}
