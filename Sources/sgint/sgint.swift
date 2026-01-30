// The Swift Programming Language
// https://docs.swift.org/swift-book
import ArgumentParser
import Foundation

@main
struct SwiftGodotIntegrate: AsyncParsableCommand {

    @Option
    var projectName: String?

    private lazy var templateLoader: ResourceLoader = .templateLoader

    mutating func run() async throws {
        print(
            try TSCNEncoder().encode(
                tscn: try GDExtension(
                    name: "ExampleGameDriver",
                    platforms: [Platform_iOS(), Platform_macOS()]
                ).tscnRepresentation
            )
        )
    }
}
