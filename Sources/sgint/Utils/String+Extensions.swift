//
//  String+Extensions.swift
//  sgint
//
//  Created by Acrylic M. on 30.01.2026.
//
import Foundation

extension String {
    
    var alphanumerics: String {
        return String(unicodeScalars.filter(CharacterSet.alphanumerics.contains))
    }
    
    mutating
    func appendLine() {
        append("\n")
    }
    
    mutating
    func appendLine(_ string: String) {
        append(string)
        appendLine()
    }
    
    func toSnakeCase() -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"
        return self
            .processCamelCaseRegex(pattern: acronymPattern)?
            .processCamelCaseRegex(pattern: normalPattern)?
            .lowercased() ?? self.lowercased()
    }
    
    fileprivate
    func processCamelCaseRegex(pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(
            in: self,
            options: [],
            range: range,
            withTemplate: "$1_$2"
        )
    }
    
    func maxSequentialRepeats(of char: Character) -> Int {
        var maxCount = 0
        var currentCount = 0
        for character in self {
            if character == char {
                currentCount += 1
                if currentCount > maxCount {
                    maxCount = currentCount
                }
            } else {
                currentCount = 0
            }
        }
        return maxCount
    }
}
