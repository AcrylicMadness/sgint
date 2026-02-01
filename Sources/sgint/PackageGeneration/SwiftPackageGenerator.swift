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
        supressWarnings: Bool = true,
        useEntryPointGenerator: Bool = true
    ) async throws {
        print("Creating Swift Package \(builder.driverName)")
        let setup = await [
            "mkdir \(builder.driverPath.path)",
            "cd \(builder.driverPath.path) && swift package init --name \(builder.driverName) --type library",
            "cd \(builder.driverPath.path) && swift package add-dependency \(swiftGodotRemote) --branch main"
        ]
        for command in setup {
            try await builder.run(command)
        }
        print("Setting up required dependencies")
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
