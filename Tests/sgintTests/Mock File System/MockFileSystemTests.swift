//
//  MockFileSystemTests.swift
//  sgint
//
//  Created by Acrylic M. on 04.02.2026.
//

import Foundation
import Testing
@testable import sgint

@Suite
struct MockFileSystemTests {
    
    let fileSystem: MockFileSystem = MockFileSystem()
    
    @Test
    func testCreateDirectory() throws {
        let expectedStructure = MockFileSystem.Node(
            name: fileSystem.currentDirectoryPath,
            isFile: false,
            children: [
                MockFileSystem.Node(
                    name: "foo",
                    isFile: false,
                    children: [
                        MockFileSystem.Node(
                            name: "bar"
                        ),
                        MockFileSystem.Node(
                            name: "baz"
                        )
                    ]
                )
            ]
        )
        try fileSystem.createDirectory(
            at: URL(fileURLWithPath: "/foo/bar"),
            withIntermediateDirectories: true
        )
        try fileSystem.createDirectory(
            at: URL(fileURLWithPath: "/foo/baz"),
            withIntermediateDirectories: true
        )
        #expect(fileSystem.rootNode == expectedStructure)
    }
    
    @Test
    func testCreateWithoutIntermidiates() throws {
        #expect(throws: MockFileSystem.Error.pathNotFound) {
            try fileSystem.createDirectory(
                at: URL(fileURLWithPath: "foo/bar/baz"),
                withIntermediateDirectories: false
            )
        }
    }
    
    @Test
    func testCreateNonExistantDirectory() throws {
        let expectedStructure = MockFileSystem.Node(name: fileSystem.currentDirectoryPath)
        try fileSystem.createDirectory(
            at: URL(fileURLWithPath: "/"),
            withIntermediateDirectories: true
        )
        try fileSystem.createDirectory(
            at: URL(fileURLWithPath: ""),
            withIntermediateDirectories: true
        )
        #expect(fileSystem.rootNode == expectedStructure)
    }
    
    @Test
    func testContentsAtPath() throws {
        try fileSystem.createDirectory(
            at: URL(fileURLWithPath: "/foo/bar"),
            withIntermediateDirectories: true
        )
        try fileSystem.createDirectory(
            at: URL(fileURLWithPath: "/foo/baz"),
            withIntermediateDirectories: true
        )
        
        let contents = try fileSystem.contentsOfDirectory(atPath: "")
        #expect(contents == ["foo"])
        
        let fooContents = try fileSystem.contentsOfDirectory(atPath: "/foo")
        #expect(fooContents == ["bar", "baz"])
        
        #expect(throws: MockFileSystem.Error.pathNotFound) {
            let _ = try fileSystem.contentsOfDirectory(atPath: "/non/existent/path")
        }
        
        let fileUrl = URL(fileURLWithPath: "/foo/bar/file")
        
        try fileSystem.write(
            string: "Something",
            to: fileUrl,
            atomically: true,
            encoding: .utf8
        )
        
        #expect(throws: MockFileSystem.Error.notADirectory) {
            let _ = try fileSystem.contentsOfDirectory(atPath: fileUrl.path)
        }
    }
    
    @Test
    func testWriteRead() throws {
        let testContents = "Hello, World!"
        let testFileName = "hello.txt"
        let testDirUrl = URL(fileURLWithPath: "/foo/bar")
        let testFileUrl = testDirUrl.appendingPathComponent(testFileName)
        
        // Create and write test file
        try fileSystem.createDirectory(
            at: testDirUrl,
            withIntermediateDirectories: true
        )
        try fileSystem.write(
            string: testContents,
            to: testFileUrl,
            atomically: true,
            encoding: .utf8
        )
        
        // Test writing files at incorrect paths
        #expect(throws: MockFileSystem.Error.pathNotFound) {
            try fileSystem.write(
                string: "Fail",
                to: URL(fileURLWithPath: ""),
                atomically: true,
                encoding: .utf8
            )
        }
        #expect(throws: MockFileSystem.Error.notAFile) {
            try fileSystem.write(
                string: "Fail",
                to: testDirUrl,
                atomically: true,
                encoding: .utf8
            )
        }
        
        // Test file existance check
        #expect(fileSystem.fileExists(atPath: testFileUrl.path))
        
        let nonExistantFileUrl = testDirUrl.appendingPathComponent("fake.txt")
        #expect(fileSystem.fileExists(atPath: nonExistantFileUrl.path) == false)
        
        let nonExistantDirUrl = URL(fileURLWithPath: "/fake/dir.txt")
        #expect(fileSystem.fileExists(atPath: nonExistantDirUrl.path) == false)
        
        // Test file reading
        let contents = try fileSystem.string(contentsOf: testFileUrl)
        #expect(contents == testContents)
        
        #expect(throws: MockFileSystem.Error.notAFile) {
            let _ = try fileSystem.string(contentsOf: testDirUrl)
        }
        
        #expect(throws: MockFileSystem.Error.pathNotFound) {
            let _ = try fileSystem.string(contentsOf: nonExistantFileUrl)
        }
    }
    
    @Test
    func testRemove() throws {
        let testFileName = "hello.txt"
        let testDirUrl = URL(fileURLWithPath: "/foo/bar")
        let testFileUrl = testDirUrl.appendingPathComponent(testFileName)
        
        try fileSystem.createDirectory(
            at: testDirUrl,
            withIntermediateDirectories: true
        )
        // Test removing file directly
        try fileSystem.write(
            string: "Hello",
            to: testFileUrl,
            atomically: true,
            encoding: .utf8
        )
        
        try fileSystem.removeItem(atPath: testFileUrl.path)
        #expect(!fileSystem.fileExists(atPath: testFileUrl.path))
        
        // Test removing file's parent directory
        try fileSystem.write(
            string: "Hello",
            to: testFileUrl,
            atomically: true,
            encoding: .utf8
        )
        
        try fileSystem.removeItem(atPath: testDirUrl.path)
        #expect(!fileSystem.fileExists(atPath: testFileUrl.path))
        #expect(!fileSystem.fileExists(atPath: testDirUrl.path))
        
        #expect(throws: MockFileSystem.Error.pathNotFound) {
            try fileSystem.removeItem(
                atPath: testDirUrl
                    .appendingPathComponent("fakefile.dir")
                    .path
            )
        }
    }
    
    @Test
    func testCopy() throws {
        let fileContent: String = "Some Content"
        let sourceFileName: String = "hello.txt"
        let sourceDirUrl = URL(fileURLWithPath: "/foo/bar")
        let sourceFileUrl = sourceDirUrl.appendingPathComponent(sourceFileName)
        
        let destinationFileName: String = "copy.txt"
        let destinationDirUrl = URL(fileURLWithPath: "/another/dir")
        let destinationFileUrl = sourceDirUrl.appendingPathComponent(destinationFileName)
        
        // Write test file
        try fileSystem.createDirectory(
            at: sourceDirUrl,
            withIntermediateDirectories: true
        )
        try fileSystem.write(
            string: fileContent,
            to: sourceFileUrl,
            atomically: true,
            encoding: .utf8
        )
        
        // Copy to non-existant directory
        #expect(throws: MockFileSystem.Error.pathNotFound) {
            try fileSystem.copyItem(at: sourceFileUrl, to: destinationDirUrl)
        }
        
        // Create destination directory and copy
        try fileSystem.createDirectory(
            at: destinationDirUrl,
            withIntermediateDirectories: true
        )
        try fileSystem.copyItem(at: sourceFileUrl, to: destinationFileUrl)
        #expect(try fileSystem.string(contentsOf: destinationFileUrl) == fileContent)
        
        // Try copying again
        #expect(throws: MockFileSystem.Error.alreadyExists) {
            try fileSystem.copyItem(at: sourceFileUrl, to: destinationFileUrl)
        }
        // Try copying to wrong url
        #expect(throws: MockFileSystem.Error.pathNotFound) {
            try fileSystem.copyItem(at: sourceFileUrl, to: URL(fileURLWithPath: ""))
        }
    }
}
