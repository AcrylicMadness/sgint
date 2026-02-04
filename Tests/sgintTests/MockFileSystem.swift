//
//  MockFileSystem.swift
//  sgint
//
//  Created by Acrylic M. on 04.02.2026.
//

import Foundation
import Testing
@testable import sgint

/// Basic file system tree emulation to avoid testing with real files
class MockFileSystem: FileOperations {
    
    class Node: Identifiable, Equatable {
        
        var name: String
        var isFile: Bool
        var children: [Node]
        var contents: String?
        
        init(
            name: String,
            isFile: Bool,
            children: [Node] = [],
            contents: String? = nil
        ) {
            self.name = name
            self.isFile = isFile
            self.children = children
            self.contents = contents
        }
        
        var id: String {
            name
        }
        
        static func == (
            lhs: MockFileSystem.Node,
            rhs: MockFileSystem.Node
        ) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    enum MockFileSystemError: Error {
        case notImplemented
    }
    
    var contents: [Node]
    
    var currentDirectoryPath: String {
        _cwd
    }
    
    private var baseNode: Node
    private let _cwd: String
    
    init(cwd: String = "testing") {
        self._cwd = cwd
        let baseNode = Node(
            name: cwd,
            isFile: false
        )
        self.baseNode = baseNode
        self.contents = [
            baseNode
        ]
    }
    
    func copyItem(
        at sourceUrl: URL,
        to destinationUrl: URL
    ) throws {
        throw MockFileSystemError.notImplemented
    }
    
    func string(contentsOf url: URL) throws -> String {
        throw MockFileSystemError.notImplemented
    }
    
    func write(
        string: String,
        to outputURL: URL,
        atomically: Bool,
        encoding: String.Encoding
    ) throws {
        throw MockFileSystemError.notImplemented    }
    
    func fileExists(atPath path: String) -> Bool {
        return false
    }
    
    func removeItem(atPath path: String) throws {
        throw MockFileSystemError.notImplemented
    }
    
    func contentsOfDirectory(atPath path: String) throws -> [String] {
        throw MockFileSystemError.notImplemented
    }
    
    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey : Any]? = nil
    ) throws {
        // Assume `withIntermediateDirectories` is always `true`
        var pathComponents = url.pathComponents
        if let first = pathComponents.first, first == "/" {
            pathComponents.removeFirst()
        }
        createDirectoryNode(for: nil, pathComponents: pathComponents)
    }
    
    private
    func createDirectoryNode(
        for node: Node?,
        pathComponents: [String]
    ) {
        var components = pathComponents
        guard let name = components.first else {
            return
        }
        components.removeFirst()
        let newNode = Node(name: name, isFile: false)
        
        if let node {
            node.children.append(newNode)
        } else {
            baseNode.children.append(newNode)
        }
        // Create more folders if needed
        if !components.isEmpty {
            createDirectoryNode(
                for: newNode,
                pathComponents: components,
            )
        }
    }
}
