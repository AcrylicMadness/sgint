//
//  TSCNEncoder.swift
//  sgint
//
//  Created by Acrylic M. on 30.01.2026.
//

import Foundation

/// Encodes TSCN container into String
final class TSCNEncoder {
    
    /// String encoding to use
    var stringEncoding: String.Encoding
    
    /// Determines if an empty line should be added after each section for readability
    var separateSections: Bool
    
    init(
        stringEncoding: String.Encoding = .utf8,
        separateSections: Bool = true
    ) {
        self.stringEncoding = stringEncoding
        self.separateSections = separateSections
    }
    
    func encode(tscn: TSCN) throws -> String {
        var result = ""
        
        for (heading, data) in tscn {
            let headingString: String
            if heading.properties.isEmpty {
                headingString = heading.name
            } else {
                let propertiesString = try heading.properties.map { key, value in
                    "\(key)=\(try formatValue(value))"
                }.joined(
                    separator: ", "
                )
                headingString = "\(heading.name) \(propertiesString)"
            }
            result.appendLine("[\(headingString)]")
            for (key, value) in data {
                result.appendLine("\(key) = \(try formatValue(value))")
            }
            if separateSections {
                result.appendLine("")
            }
        }
        return result
    }
    
    private func formatValue(_ value: Codable) throws -> String {
        let data = try JSONEncoder().encode(value)
        guard let string = String(data: data, encoding: stringEncoding) else {
            throw EncodingError.stringConversionFailed(usingEncoding: stringEncoding)
        }
        return string.replacingOccurrences(of: "\\", with: "")
    }
    
    enum EncodingError: Error {
        case stringConversionFailed(usingEncoding: String.Encoding)
    }
}
