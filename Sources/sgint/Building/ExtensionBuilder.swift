//
//  Builder.swift
//  sgint
//
//  Created by Acrylic M. on 30.01.2026.
//

import Foundation

/// ExtensionBuilder that provides platform with build information and shell access
actor ExtensionBuilder {
    actor Output {
        private var content: String = ""
        
        func printLine(_ line: String) {
            print(line, terminator: line.hasSuffix("\n") ? "" : "\n")
            appendLine(line)
        }
        
        func appendLine(_ line: String) {
            content.appendLine(line)
        }
        
        @discardableResult
        func drain() -> String {
            let output = content
            content = ""
            return output
        }
    }
    
    enum ShellType: String, CaseIterable {
        case zsh = "/bin/zsh"
        case sh = "/bin/sh"
        case cmd = "C:\\Windows\\System32\\cmd.exe"
    }
    
    // MARK: - Properties
    let projectName: String
    let driverName: String
    let workingDirectory: URL
    let fileSystem: FileOperations
    let binFolderName: String
    let swiftRuntimeDirName: String
    
    var buildMode: BuildMode = .debug
    var buildArch: Architecture = .aarch64
    
    var driverPath: URL {
        workingDirectory.appendingPathComponent("\(driverName)")
    }
    
    private let output: Output = Output()
    private let shellUrl: URL
    
    // MARK: - Public Methods
    init(
        projectName: String,
        driverName: String,
        workingDirectory: URL,
        binFolderName: String,
        swiftRuntimeDirName: String,
        fileSystem: FileOperations
    ) throws {
        self.projectName = projectName
        self.driverName = driverName
        self.workingDirectory = workingDirectory
        self.fileSystem = fileSystem
        self.binFolderName = binFolderName
        self.swiftRuntimeDirName = swiftRuntimeDirName
        
        var detectedShellUrl: URL?
        
        for path in ShellType.allCases.map({ $0.rawValue }) {
            if fileSystem.fileExists(atPath: path) {
                detectedShellUrl = URL(fileURLWithPath: path)
                print("Using \(path)")
                break
            }
        }
        guard let detectedShellUrl else {
            throw BuildError.unableToLocateShell
        }
        self.shellUrl = detectedShellUrl
    }
    
    func prepare(
        forMode buildMode: BuildMode,
        with arch: Architecture
    ) async {
        await output.drain()
        self.buildMode = buildMode
        self.buildArch = arch
    }
    
    /// Executes shell command and continuously prints and saves its output
    /// - Parameter command: Command to execute
    /// - Returns: Command output
    @discardableResult
    func run(
        _ command: String,
    ) async throws -> String {
        print("Running: \(command)")
        
        let outputPipe = Pipe()
        let task = try self.createProcess([command], outputPipe)
        
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            if let line = self?.getOutput(outputPipe, fileHandle) {
                // Far from the best way to do it, but AsyncBytes is not available on Linux
                Task { @MainActor in
                    await self?.output.printLine(line)
                }
            }
        }
        try task.run()
        task.waitUntilExit()
        
        guard task.terminationStatus == 0 else {
            throw BuildError.buildFailed(terminationStatus: task.terminationStatus)
        }
        return await output.drain()
    }
    
    func copyExtensionBinaries(
        from binPath: String,
        for platform: any Platform,
        with arch: Architecture?
    ) throws {
        // On Windows, we also need to copy .pdp and .lib files,
        // but there is no need to specify them in .gdextension
        guard let libraries = getLibrariesToCopy(
            for: platform,
            with: driverName
        ) else {
            throw ExtensionBuilder.BuildError.failedToMapBinariesPaths
        }
        for library in libraries {
            print("Copying extension library: \(library)")
            
            let originDirectoryUrl = URL(fileURLWithPath: binPath)
            let destinationDirectoryUrl = binDestinationDirectory(
                for: platform,
                with: arch
            )
            try copyFile(
                named: library,
                from: originDirectoryUrl,
                to: destinationDirectoryUrl
            )
        }
    }
    
    func identifyAndCopyRuntimeLibraries(
        from binPath: String,
        for platform: any Platform,
        with arch: Architecture?
    ) throws -> [String] {
        let files = try fileSystem.contentsOfDirectory(atPath: binPath)
        var runtimeLibraries: [String] = []
        
        for fileName in files {
            if fileName.contains(platform.mainLibExtension) {
                print("Copying Swift Runtime library: \(fileName)")
                
                let originDirectoryUrl = URL(fileURLWithPath: binPath)
                let destinationDirectoryUrl = binDestinationDirectory(
                    for: platform,
                    with: arch
                )
                try copyFile(
                    named: fileName,
                    from: originDirectoryUrl,
                    to: destinationDirectoryUrl
                )
                runtimeLibraries.append(fileName)
            }
        }
        return runtimeLibraries
    }
    
    /// Provides appropriate URL for binaries to be copied to
    /// - Returns: Directory URL with format: `bin/(driver)/(platform)-(arch)/(component)`
    func binDestinationDirectory(
        for platform: any Platform,
        with arch: Architecture?
    ) -> URL {
        workingDirectory
            .appendingPathComponent(binFolderName)
            .appendingPathComponent(driverName)
            .appendingPathComponent(platform.directory(for: arch))
            .appendingPathComponent(buildMode.rawValue)
    }
    
    // MARK: - Private Methods
    private
    func createProcess(
        _ arguments: [String],
        _ pipe: Pipe
    ) throws -> Process {
        let task = Process()
        task.executableURL = shellUrl
#if os(Windows)
        task.arguments = ["/c"] + arguments
#else
        task.arguments = ["-c"] + arguments
#endif
        task.standardOutput = pipe
        task.standardError = pipe
        return task
    }

    private
    nonisolated func getOutput(
        _ pipe: Pipe,
        _ fileHandle: FileHandle
    ) -> String? {
        let data = fileHandle.availableData
        guard data.count > 0 else {
            pipe.fileHandleForReading.readabilityHandler = nil
            return nil
        }
        guard let line = String(data: data, encoding: .utf8) else {
            return nil
        }
        return line
    }
    
    private
    func getLibrariesToCopy(
        for platform: any Platform,
        with driverName: String
    ) -> [String]? {
        guard let mainLibraries = Array<String>(
            mirrorChildValuesOf: (
                platform.getMainLibNames(for: driverName)
            )
        ) else {
            return nil
        }
        guard let additionalLibraries = Array<String>(
            mirrorChildValuesOf: (
                platform.getAdditionalLibNames(for: driverName)
            )
        ) else {
            return nil
        }
        return mainLibraries + additionalLibraries
    }
    
    private
    func copyFile(
        named filename: String,
        from originDirectoryUrl: URL,
        to destinationDirectoryUrl: URL
    ) throws {
        let originFileUrl = originDirectoryUrl
            .appendingPathComponent(filename)
        
        if !fileSystem.fileExists(atPath: destinationDirectoryUrl.path) {
            try fileSystem.createDirectory(
                at: destinationDirectoryUrl,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        let destinationFileUrl = destinationDirectoryUrl
            .appendingPathComponent(filename)
        
        if fileSystem.fileExists(atPath: destinationFileUrl.path) {
            try fileSystem.removeItem(atPath: destinationFileUrl.path)
        }
        try fileSystem.copyItem(at: originFileUrl, to: destinationFileUrl)
    }

    enum BuildError: Error {
        case buildFailed(terminationStatus: Int32)
        case unableToLocateShell
        case failedToMapBinariesPaths
    }
}
