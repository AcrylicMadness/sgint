//
//  FileSystem.swift
//  sgint
//
//  Created by Acrylic M. on 04.02.2026.
//

import Foundation

class FileSystem: FileOperations {
    
    private let fileManager: FileManager
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }
    
    var currentDirectoryPath: String {
        fileManager.currentDirectoryPath
    }
    
    func copyItem(
        at sourceUrl: URL,
        to destinationUrl: URL
    ) throws {
        try fileManager.copyItem(
            at: sourceUrl,
            to: destinationUrl
        )
    }
    
    func string(contentsOf url: URL) throws -> String {
        try String(contentsOf: url)
    }
    
    func write(
        string: String,
        to outputURL: URL,
        atomically: Bool,
        encoding: String.Encoding
    ) throws {
        try string.write(
            to: outputURL,
            atomically: atomically,
            encoding: encoding
        )
    }
    
    func fileExists(
        atPath path: String
    ) -> Bool {
        fileManager.fileExists(atPath: path)
    }
    
    func removeItem(
        atPath path: String
    ) throws {
        try fileManager.removeItem(atPath: path)
    }
    
    func contentsOfDirectory(atPath path: String) throws -> [String] {
        try fileManager.contentsOfDirectory(atPath: path)
    }
    
    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey : Any]? = nil
    ) throws {
        try fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: createIntermediates,
            attributes: attributes
        )
    }
    
    
}
