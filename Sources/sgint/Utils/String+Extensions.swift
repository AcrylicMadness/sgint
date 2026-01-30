//
//  String+Extensions.swift
//  sgint
//
//  Created by Acrylic M. on 30.01.2026.
//
import Foundation

extension String {
    
    mutating
    func appendLine() {
        append("\n")
    }
    
    mutating
    func appendLine(_ string: String) {
        append(string)
        appendLine()
    }
    
    func camelCaseToSnakeCase() -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"
        return self
            .processCamalCaseRegex(pattern: acronymPattern)?
            .processCamalCaseRegex(pattern: normalPattern)?
            .lowercased() ?? self.lowercased()
    }
    
    fileprivate func processCamalCaseRegex(pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(
            in: self,
            options: [],
            range: range,
            withTemplate: "$1_$2"
        )
    }
}
