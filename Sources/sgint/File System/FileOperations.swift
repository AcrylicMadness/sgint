//
//  FileOperations.swift
//  sgint
//
//  Created by Acrylic M. on 04.02.2026.
//

import Foundation

protocol FileOperations {
    
    var currentDirectoryPath: String { get }
    
    func copyItem(
        at sourceUrl: URL,
        to destinationUrl: URL
    ) throws
    
    func string(
        contentsOf url: URL
    ) throws -> String
    
    func write(
        string: String,
        to outputURL: URL,
        atomically: Bool,
        encoding: String.Encoding
    ) throws
    
    func fileExists(
        atPath path: String
    ) -> Bool
    
    func removeItem(
        atPath path: String
    ) throws
    
    func contentsOfDirectory(
        atPath path: String
    ) throws -> [String]
    
    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey : Any]?
    ) throws
}
