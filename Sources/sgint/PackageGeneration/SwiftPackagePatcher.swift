//
//  SwiftPackagePatcher.swift
//  sgint
//
//  Created by Acrylic M. on 01.02.2026.
//

import Foundation
import RegexBuilder

class SwiftPackagePatcher {
    
    struct Patch {
        let additionalLines: [String]
        let patchingSection: String?
        let insertAfter: String?
    }
    
    private(set) var contents: String
    private let swiftPackageUrl: URL
    private let suppressWarnings: Bool
    private let useEntryPointGenerator: Bool
    private let macOsVersion: String
    private let iosVersion: String
    private let fileSystem: FileOperations
    
    private let swiftGodotDependency: String = "SwiftGodot"
    private let entryPointGenerator: String = "EntryPointGeneratorPlugin"
    
    private lazy var patches: [Patch] = {
        // Set minimum platform versions required by SwiftGodot
        let platformPatch = Patch(
            additionalLines: ["platforms: [.macOS(\(macOsVersion)), .iOS(\(iosVersion))],"],
            patchingSection: nil,
            insertAfter: "name:"
        )
        // Make library dynamic
        let dynamicLibraryPatch = Patch(
            additionalLines: ["type: .dynamic,"],
            patchingSection: "library",
            insertAfter: "name:"
        )
        // Add SwiftGodot as dependency to main target
        var targetLines = ["dependencies: [ \"\(swiftGodotDependency)\"],"]
        // Supress warnings is requested
        if suppressWarnings {
            targetLines.append("swiftSettings: [.unsafeFlags([\"-suppress-warnings\"])],")
        }
        // Use entry point generator, to avoiod manually
        // exposing each class to Godot
        if useEntryPointGenerator {
            targetLines.append("plugins: [.plugin(name: \"\(entryPointGenerator)\", package: \"\(swiftGodotDependency)\")]")
        }
        let targetPatch = Patch(
            additionalLines: targetLines,
            patchingSection: "target",
            insertAfter: "name:"
        )
        return [platformPatch, dynamicLibraryPatch, targetPatch]
    }()
    
    init(
        macOsVersion: String,
        iosVersion: String,
        swiftPackageUrl: URL,
        supressWarnings: Bool,
        useEntryPointGenerator: Bool,
        fileSystem: FileOperations
    ) throws {
        self.macOsVersion = macOsVersion
        self.iosVersion = iosVersion
        self.swiftPackageUrl = swiftPackageUrl
        self.suppressWarnings = supressWarnings
        self.useEntryPointGenerator = useEntryPointGenerator
        self.fileSystem = fileSystem
        self.contents = try fileSystem.string(
            contentsOf: swiftPackageUrl,
            encoding: .utf8
        )
    }
    
    func patch() throws {
        for patch in patches {
            apply(patch: patch)
        }
        try contents.write(
            to: swiftPackageUrl,
            atomically: true,
            encoding: .utf8
        )
    }
    
    private
    func apply(
        patch: Patch
    ) {
        let regex: Regex<(Substring, Substring)>
        
        if let patchingSection = patch.patchingSection {
            // Capturing required section
            // \.patchingSection\(([^)]*)\),
            regex = Regex {
                ".\(patchingSection)("
                Capture {
                    ZeroOrMore(CharacterClass.anyOf(")").inverted)
                }
                ")"
            }
        } else {
            // Capture entire Package content
            // Package\(([^{}]*)
            regex = Regex {
                "Package("
                Capture {
                    ZeroOrMore(CharacterClass.anyOf("{}").inverted)
                }
                ")"
            }
        }
        
        for match in contents.matches(of: regex) {
            var lines = "\(match.1)"
                .split(separator: "\n")
                .map({ String($0) })
            
            var indentation: (char: Character, amount: Int)?
            var insertionIndex: Int?
            
            if let firstLine = lines.first {
                let firstChar = firstLine[firstLine.startIndex]
                indentation = (firstChar, firstLine.maxSequentialRepeats(of: firstChar))
            }
            if let after = patch.insertAfter {
                // When working with entire Package() capture, we only
                // need to insert 'platforms' right after first 'name:',
                // so this will work fine.
                insertionIndex = lines.firstIndex(where: { $0.contains(after) })
            }
            
            for (lineIndex, line) in patch.additionalLines.enumerated() {
                var newLine: String = line
                
                // Try to insert matching indentation
                if let indentation {
                    newLine.insert(
                        contentsOf: String(
                            repeating: indentation.char,
                            count: indentation.amount
                        ),
                        at: newLine.startIndex
                    )
                }
                if let insertionIndex {
                    if lines[insertionIndex + lineIndex].last != "," {
                        lines[insertionIndex + lineIndex].append(",")
                    }
                    lines.insert(newLine, at: insertionIndex + lineIndex + 1)
                } else {
                    if lines.last?.last != "," {
                        lines[lines.count - 1].append(",")
                    }
                    lines.append(newLine)
                }
            }
            
            // Some line breaks to keep formatting nice
            var patchedSection = "\n" + lines.joined(separator: "\n")
            if patch.patchingSection == nil {
                patchedSection.append("\n")
            }
            
            contents.removeSubrange(match.1.startIndex..<match.1.endIndex)
            contents.insert(contentsOf: patchedSection, at: match.1.startIndex)
        }
    }
    
    enum PatchingError: Error {
        case packageSwiftIsEmpty
    }
}
