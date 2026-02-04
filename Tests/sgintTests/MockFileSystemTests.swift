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
        let expectedStructure = [
            MockFileSystem.Node(
                name: fileSystem.currentDirectoryPath,
                isFile: false,
                children: [
                    MockFileSystem.Node(
                        name: "foo",
                        isFile: false,
                        children: [
                            MockFileSystem.Node(
                                name: "bar",
                                isFile: false,
                                children: []
                            )
                        ]
                    )
                ]
            )
        ]
        try fileSystem.createDirectory(
            at: URL(fileURLWithPath: "/foo/bar"),
            withIntermediateDirectories: true
        )
        #expect(fileSystem.contents == expectedStructure)
    }
}
