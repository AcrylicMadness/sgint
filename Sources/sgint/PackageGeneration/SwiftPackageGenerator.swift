//
//  SwiftPackageGenerator.swift
//  sgint
//
//  Created by Acrylic M. on 01.02.2026.
//

actor SwiftPackageGenerator {
    
    private let swiftGodotRemote = "https://github.com/migueldeicaza/SwiftGodot.git"
        
    func generate(
        with builder: ExtensionBuilder,
        supressWarnings: Bool = false,
        useEntryPointGenerator: Bool = true
    ) async throws {
        print("Creating Swift Package \(builder.driverName)")
        // We create standard library and then patch its definition
        // to turn it into dynamic library.
        // The other approach is to run
        // swift package init --name (name) --type empty
        // swift package add-product --type dynamic-library --name (name)
        // But this approach will not auto-generate complete
        // file structure (that includes test).
        try await builder.fileSystem.createDirectory(
            at: builder.driverPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
        let setup = [
            "cd \(builder.driverName) && swift package init --name \(builder.driverName) --type library",
            "cd \(builder.driverName) && swift package add-dependency \(swiftGodotRemote) --branch main"
        ]
        for command in setup {
            try await builder.run(command)
        }
        print("Setting up required dependencies")
        // Edit Package.swift to work with SwiftGodot
        let patcher = try await SwiftPackagePatcher(
            macOsVersion: ".v15",
            iosVersion: ".v17",
            swiftPackageUrl: builder.driverPath.appendingPathComponent("Package.swift"),
            supressWarnings: supressWarnings,
            useEntryPointGenerator: useEntryPointGenerator
        )
        
        try patcher.patch()
    }
}
