//
//  ResourceLoader.swift
//  sgint
//
//  Created by Acrylic M. on 30.01.2026.
//

import Foundation

struct ResourceLoader: Decodable {
    let path: String?
    let defaultExtension: String?

    func loadResource(
        withName name: String,
        fileExtension: String? = nil
    ) throws -> Data {
        // Bundle.module does not reutrn correct url when building with Xcode
        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: fileExtension ?? defaultExtension,
            subdirectory: path
        ) else {
            throw ResourceError.resourceNotFound
        }
        return try Data(contentsOf: url)
    }

    func loadString(
        fromFileWithName name: String,
        fileExtension: String? = nil,
        encoding: String.Encoding = .utf8
    ) throws -> String {
        let data = try loadResource(withName: name, fileExtension: fileExtension)
        guard let string = String(data: data, encoding: encoding) else {
            throw ResourceError.notConvertableToString
        }
        return string
    }

    enum ResourceError: Error {
        case resourceNotFound
        case notConvertableToString
    }
}

extension ResourceLoader {
    static let templateLoader = ResourceLoader(
        path: "Templates",
        defaultExtension: "sgtmp"
    )
}
