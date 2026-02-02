// The Swift Programming Language
// https://docs.swift.org/swift-book
import ArgumentParser
import Foundation

@main
struct SwiftGodotIntegrate: AsyncParsableCommand {
    
    // MARK: - Command Arguments
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
        help: "Build configurations to use."
    )
    var configuration: [BuildMode] = [.debug]
    
    @Option(
        name: .shortAndLong,
        help: "Architectures to build for."
    )
    var arch: [Architecture] = []
    
    @Flag(
        name: .shortAndLong,
        help: "Exports project after build is completed."
    )
    var export: Bool = false
    
    // MARK: - Properties
    private lazy var binFolderName: String = "bin"
    private lazy var swiftRuntimeDir: String = "swift-runtime"
    private lazy var templateLoader: ResourceLoader = .templateLoader
    private lazy var tscnEncoder: TSCNEncoder = TSCNEncoder(separateSections: true)
    private lazy var packageGenerator: SwiftPackageGenerator = SwiftPackageGenerator()
    
    private var identifiedDependencies: [String: [String]] = [:]
    
    private var fileManager: FileManager {
        FileManager.default
    }
    
    var workingDirectory: URL {
        URL(fileURLWithPath: fileManager.currentDirectoryPath)
    }
    
    var platforms: [any Platform] {
        targets.map({ $0.associatedPlatform })
    }
    
    // MARK: - Command Execution
    mutating func run() async throws {
        if action.requiresTargetValidation {
            try validateTargets()
        }
        
        if arch.isEmpty {
            try arch.append(Architecture.current)
        }
        
        let currentProjectName = projectName ?? workingDirectory.lastPathComponent
        let currentDriverName = driverName ?? "\(currentProjectName.alphanumerics)Driver"
        
        let builder = try ExtensionBuilder(
            projectName: currentProjectName,
            driverName: currentDriverName,
            workingDirectory: workingDirectory,
            binFolderName: binFolderName,
            swiftRuntimeDirName: swiftRuntimeDir,
            fileManager: fileManager
        )
        
        switch action {
        case .integrate:
            // TODO: Validate that Swift Package does not exist
            try await packageGenerator.generate(with: builder)
        case .build:
            printBuildConfig(projectName: currentProjectName)
            try await buildRequestedPlatforms(withBuilder: builder)
            try makeExtensionFile(
                forDriver: currentDriverName,
                platformDependencies: identifiedDependencies
            )
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
            if [.ios, .iossimulator].contains(target) {
                // iOS and iOS Simulator can be built only on macOS through Xcode
                if currentTarget != .macos {
                    throw Target.TargetDetectError.iosBuildsRequireMacOS
                }
            } else {
                // Cross-compiling is not supported yet
                // I will look into Swift Linux Static SDK later
                if currentTarget != target {
                    throw Target.TargetDetectError.crossCompilingIsNotSupported
                }
            }
        }
        // Godot Extensions do not support separate entries for iOS and iOS Simulator
        // So only one of those should be built at a time
        if targets.contains(array: [.ios, .iossimulator]) {
            throw Target.TargetDetectError.cannotBuildForBothDeviceAndSimulator
        }
    }
    
    private mutating
    func buildRequestedPlatforms(
        withBuilder builder: ExtensionBuilder
    ) async throws {
        for platform in platforms {
            for mode in configuration {
                if platform.separateArchs {
                    // Build for requested architectures separately
                    for architecture in arch {
                        guard platform.supportedArchs.contains(architecture) else {
                            print("Skipping \(architecture.rawValue) build for \(platform.name)")
                            continue
                        }
                        try await buildPlatform(
                            platform,
                            for: architecture,
                            in: mode,
                            withBuilder: builder
                        )
                    }
                } else {
                    // For iOS, xcodebuild manages architectures on its own
                    // Passed architecture here will be ignored
                    try await buildPlatform(
                        platform,
                        for: nil,
                        in: mode,
                        withBuilder: builder
                    )
                }
            }
        }
    }
    
    private mutating
    func buildPlatform(
        _ platform: any Platform,
        for architecture: Architecture?,
        in mode: BuildMode,
        withBuilder builder: ExtensionBuilder
    ) async throws {
        var buildInfo = "Building for: \(platform.id)-\(mode)"
        if let architecture {
            buildInfo.append("-\(architecture.rawValue)")
        }
        print(buildInfo)
        await builder.prepare(forMode: mode, with: architecture ?? .aarch64)
        let binPath = try await platform.build(using: builder)
        try await builder.copyExtensionBinaries(
            from: binPath,
            for: platform,
            with: architecture
        )
        if let swiftRuntimePath = try await platform.getRuntimeLibPath(using: builder) {
            let runtimeLibraries = try await builder.identifyAndCopyRuntimeLibraries(
                from: swiftRuntimePath,
                for: platform,
                with: architecture
            )
            identifiedDependencies[platform.directory(for: architecture)] = runtimeLibraries
        }
        
    }
    
    private mutating
    func makeExtensionFile(
        forDriver name: String,
        platformDependencies: [String: [String]]
    ) throws {
        print("Creating .gdextension file")
        let gdExtension = GDExtension(
            name: name,
            platforms: platforms,
            archs: arch,
            buildModes: configuration,
            platformDependencies: platformDependencies,
            swiftRuntimeDir: swiftRuntimeDir
        )
        let content = try tscnEncoder.encode(tscn: gdExtension.tscnRepresentation)
        let outputUrl = workingDirectory
            .appendingPathComponent(binFolderName)
            .appendingPathComponent("\(name).gdextension")
        try content.write(to: outputUrl, atomically: true, encoding: .utf8)
    }
    
    private
    func printBuildConfig(projectName: String) {
        print("Build Configuration:")
        print("Project: \(projectName)")
        print("Modes: \(configuration.map({ $0.rawValue }))")
        print("Platforms: \(targets.map({ $0.rawValue }))")
        print("Architectures: \(arch.map({ $0.rawValue }))")
    }
}
