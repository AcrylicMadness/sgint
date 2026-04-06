//
//  TSCNEncoderTests.swift
//  sgint
//
//  Created by Acrylic M. on 06.04.2026.
//

import Testing
@testable import sgint

@Suite
struct TSCCNEncoderTests {
    
    struct TestJson: Codable, Hashable {
        let field: String
        
        init(field: String = "value") {
            self.field = field
        }
    }
    
    let stringEncoding: String.Encoding = .utf8
    let tscn: TSCN = [
        TSCNHeading(name: "first"): [
            "string": "bar",
            "string_that_needs_escaping": "\\string",
            "non_ascii_character": "ъ",
            "json": TestJson()
        ],
        TSCNHeading(name: "second", properties: [
            "heading_property": "value"
        ]): [
            "number": 1.1,
            "dictionary": ["key": "value"]
        ]
    ]
    
    let expectedPlainResult: String = """
        [first]
        string = "bar"
        string_that_needs_escaping = "string"
        non_ascii_character = "ъ"
        json = {"field":"value"}
        [second heading_property="value"]
        number = 1.1
        dictionary = {"key":"value"}
        """
    
    let expectedPrettyResult: String = """
        [first]
        string = "bar"
        string_that_needs_escaping = "string"
        non_ascii_character = "ъ"
        json = {"field":"value"}

        [second heading_property="value"]
        number = 1.1
        dictionary = {"key":"value"}
        """
    
    @Test
    func testPlainEncoding() throws {
        let encoder = TSCNEncoder(
            stringEncoding: stringEncoding,
            separateSections: false
        )
        let result = try encoder.encode(tscn: tscn)
        #expect(result == expectedPlainResult)
    }
    
    @Test
    func testPrettyEncoding() throws {
        let encoder = TSCNEncoder(
            stringEncoding: stringEncoding,
            separateSections: true
        )
        let result = try encoder.encode(tscn: tscn)
        #expect(result == expectedPrettyResult)
    }
    
    @Test
    func testBadEncoding() throws {
        let badEncoding: String.Encoding = .ascii
        
        let encoder = TSCNEncoder(
            stringEncoding: badEncoding,
            separateSections: true
        )
        #expect(
            throws: TSCNEncoder.EncodingError.stringConversionFailed(
                usingEncoding: badEncoding
            )
        ) {
            let _ = try encoder.encode(tscn: tscn)
        }
    }
}
