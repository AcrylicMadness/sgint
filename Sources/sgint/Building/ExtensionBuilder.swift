//
//  Builder.swift
//  sgint
//
//  Created by Acrylic M. on 30.01.2026.
//

import Foundation

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
    
    // MARK: - Properties
    let projectName: String
    let driverName: String
    let workingDirectory: URL
    let fileManager: FileManager
    let binFolderName: String
    
    var buildMode: BuildMode = .debug
    var buildArch: Architecture = .aarch64
    
    var driverPath: URL {
        workingDirectory.appendingPathComponent("\(driverName)")
    }
    
    private let output: Output = Output()
    
    // MARK: - Public Methods
    init(
        projectName: String,
        driverName: String,
        workingDirectory: URL,
        binFolderName: String,
        fileManager: FileManager
    ) {
        self.projectName = projectName
        self.driverName = driverName
        self.workingDirectory = workingDirectory
        self.fileManager = fileManager
        self.binFolderName = binFolderName
    }
    
    func prepare(
        forMode buildMode: BuildMode,
        with arch: Architecture
    ) async {
        await output.drain()
        self.buildMode = buildMode
        self.buildArch = arch
    }
    
    @discardableResult
    func run(
        _ command: String,
    ) async throws -> String {
        print("Running: \(command)")
        let outputPipe = Pipe()
        let task = self.createProcess([command], outputPipe)
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
        with arch: Architecture
    ) throws {
        guard let libraries = Array<String>(
            mirrorChildValuesOf: (
                platform.getLibNames(for: driverName)
            )
        ) else {
            throw ExtensionBuilder.BuildError.failedToMapBinariesPaths
        }
        for library in libraries {
            print("Copying \(library)")
            
            let originUrl = URL(fileURLWithPath: binPath)
                .appendingPathComponent(library)
            
            let destinationDirectoryUrl = workingDirectory
                .appendingPathComponent(binFolderName)
                .appendingPathComponent(driverName)
                .appendingPathComponent("\(platform.name)-\(arch.rawValue)")
                .appendingPathComponent(buildMode.rawValue)
            
            if !fileManager.fileExists(atPath: destinationDirectoryUrl.path) {
                try fileManager.createDirectory(
                    at: destinationDirectoryUrl,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
            let destinationUrl = destinationDirectoryUrl
                .appendingPathComponent(library)
            
            if fileManager.fileExists(atPath: destinationUrl.path) {
                try fileManager.removeItem(atPath: destinationUrl.path)
            }
            try fileManager.copyItem(at: originUrl, to: destinationUrl)
        }
    }
    
    func copySwiftRuntimeBinaries(
        for platform: any Platform,
        with arch: Architecture
    ) {
        // TODO: Copy Swift Runtime binaries on Windows/Linux
    }
    
    // MARK: - Private Methods
    private
    func createProcess(
        _ arguments: [String],
        _ pipe: Pipe
    ) -> Process {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-c"] + arguments
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

    enum BuildError: Error {
        case buildFailed(terminationStatus: Int32)
        case failedToMapBinariesPaths
    }
}
