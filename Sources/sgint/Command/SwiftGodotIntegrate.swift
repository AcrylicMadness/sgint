// The Swift Programming Language
// https://docs.swift.org/swift-book
import ArgumentParser
import Foundation

@main
struct SwiftGodotIntegrate: AsyncParsableCommand {
    
    // MARK: - Command arguments
    @Argument(
        help: "Action to perform. Defaults to build. Available: \n\n\(Action.helpMessage)"
    )
    var action: Action = .build

    @Option(
        name: .shortAndLong,
        help: "Platforms to target the builds. Defaults to current platform only."
    )
    var targets: [Target] = []
    
    @Option(
        name: .shortAndLong,
        help: "Name of the project. Inferred from the current directory if not specified."
    )
    var projectName: String?
    
    @Option(
        name: .shortAndLong,
        help: "Name of SPM package inside of your Godot project. Defaults to '{PROJECTNAME}Driver'."
    )
    var driverName: String?
    
    @Option(
        name: .shortAndLong,
        help: "Build configurations to use"
    )
    var configuration: [BuildMode] = [.debug]
    
    @Option(
        name: .shortAndLong,
        help: "Architectures to build for"
    )
    var arch: [Architecture] = []
    
    // MARK: - Properties
    private lazy var binFolderName: String = "bin"
    private lazy var templateLoader: ResourceLoader = .templateLoader
    private lazy var tscnEncoder: TSCNEncoder = TSCNEncoder(separateSections: true)
    
    private var fileManager: FileManager {
        FileManager.default
    }
    
    var workingDirectory: URL {
        URL(fileURLWithPath: fileManager.currentDirectoryPath)
    }
    
    var platforms: [any Platform] {
        targets.map({ $0.associatedPlatform })
    }

    // 20 Build binaries for specified platform (or auto-detect current platform)
    // 30 Move binaries to bin folder (create if needed)
    // 40 Generate and output gdextension manifest
    
    // Add option to setup vscode actions
    // MARK: - Command Execution
    mutating func run() async throws {
        if action.requiresTargetValidation {
            try validateTargets()
        }
        
        let currentProjectName = projectName ?? workingDirectory.lastPathComponent
        let currentDriverName = driverName ?? "\(currentProjectName.alphanumerics)Driver"
        
        switch action {
        case .integrate:
            fatalError("Not implemented")
        case .build:
            try await buildExtension(
                driverName: currentDriverName,
                projectName: currentProjectName
            )
        case .export:
            fatalError("Not implemented")
        case .setupVscodeActions:
            fatalError("Not implemented")
        }
    }
    
    // MARK: - Private Methods
    private mutating
    func validateTargets() throws {
        let currentTarget = try Target.current
        if targets.isEmpty {
            targets.append(currentTarget)
        }
        for target in targets {
            if target == .ios, currentTarget != .macos {
                throw Target.TargetDetectError.iosBuildsRequireMacOS
            }
            if target != .ios, currentTarget != target {
                throw Target.TargetDetectError.crossCompilingIsNotSupported
            }
        }
    }
    
    private mutating
    func buildExtension(
        driverName: String,
        projectName: String
    ) async throws {
        let builder = ExtensionBuilder(
            projectName: projectName,
            driverName: driverName,
            workingDirectory: workingDirectory,
            binFolderName: binFolderName,
            buildArchs: arch,
            fileManager: fileManager
        )
        try await buildPlatforms(withBuilder: builder)
        try makeExtensionFile(forDriver: driverName)
    }
    
    private mutating
    func buildPlatforms(
        withBuilder builder: ExtensionBuilder
    ) async throws {
        for platform in platforms {
            for mode in configuration {
                print("Building for target: \(platform.name)-\(mode)")
                await builder.prepare(forMode: mode)
                let binPath = try await platform.build(using: builder)
                try await builder.copyBinaries(from: binPath, for: platform)
            }
        }
    }
    
    private mutating
    func makeExtensionFile(
        forDriver name: String
    ) throws {
        print("Creating .gdextension file")
        let gdExtension = GDExtension(
            name: name,
            platforms: platforms,
            buildModes: configuration
        )
        let content = try tscnEncoder.encode(tscn: gdExtension.tscnRepresentation)
        let outputUrl = workingDirectory
            .appendingPathComponent(binFolderName)
            .appendingPathComponent("\(name).gdextension")
        try content.write(to: outputUrl, atomically: true, encoding: .utf8)
    }
}
