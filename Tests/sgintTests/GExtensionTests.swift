import Foundation
import Testing
@testable import sgint

@Suite
struct GDExtensionTests {
    
    let swiftEntryPoint = GDExtension.Configuration.standard.entrySymbol
    let compatibilityMinimum = GDExtension.Configuration.standard.compatibilityMinimum
    
    @Test
    func testExtensionGenerationNoRuntime() throws {
        
        let expectedResult: TSCN = [
            "configuration": [
                "entry_symbol": swiftEntryPoint,
                "compatibility_minimum": compatibilityMinimum
            ],
            "libraries": [
                "macos.release.arm64": "macos-aarch64/release/libTestExtension.dylib",
                "macos.release.x86_64": "macos-x86_64/release/libTestExtension.dylib"
            ],
            "dependencies": [
                "macos.release.arm64": [
                    "macos-aarch64/release/libSwiftGodot.dylib": ""
                ],
                "macos.release.x86_64": [
                    "macos-x86_64/release/libSwiftGodot.dylib": ""
                ]
            ]
        ]
        
        let gdExtension = GDExtension(
            name: "TestExtension",
            platforms: [Platform_macOS()],
            archs: [.aarch64, .x86_64],
            configuration: .standard,
            binLocation: "bin",
            buildModes: [.release],
            platformDependencies: [:],
            swiftRuntimeDir: "swift"
        )
        try compareTscn(
            actual: gdExtension.tscnRepresentation,
            to: expectedResult
        )
    }
    
    @Test
    func testExtensionGenerationWithRuntime() throws {
        let armDependency = "dependency-arm.so"
        let x86Dependency = "dependency-x86.so"
        
        let expectedResult: TSCN = [
            "configuration": [
                "entry_symbol": swiftEntryPoint,
                "compatibility_minimum": compatibilityMinimum
            ],
            "libraries": [
                "linux.release.arm64": "linux-aarch64/release/libTestExtension.so",
                "linux.release.x86_64": "linux-x86_64/release/libTestExtension.so"
            ],
            "dependencies": [
                "linux.release.arm64": [
                    "linux-aarch64/release/libSwiftGodot.so": "",
                    "linux-aarch64/release/\(armDependency)": ""
                ],
                "linux.release.x86_64": [
                    "linux-x86_64/release/libSwiftGodot.so": "",
                    "linux-x86_64/release/\(x86Dependency)": ""
                ]
            ]
        ]
        
        let gdExtension = GDExtension(
            name: "TestExtension",
            platforms: [Platform_Linux()],
            archs: [.aarch64, .x86_64],
            configuration: .standard,
            binLocation: "bin",
            buildModes: [.release],
            platformDependencies: [
                "linux-aarch64": [armDependency],
                "linux-x86_64": [x86Dependency]
            ],
            swiftRuntimeDir: "swift"
        )
        try compareTscn(
            actual: gdExtension.tscnRepresentation,
            to: expectedResult
        )
    }
    
    @Test
    func testExtensionGenerationPlatfromControlledArch() throws {
        let expectedResult: TSCN = [
            "configuration": [
                "entry_symbol": swiftEntryPoint,
                "compatibility_minimum": compatibilityMinimum
            ],
            "libraries": [
                "ios.release": "ios/release/TestExtension.framework",
            ],
            "dependencies": [
                "ios.release": [
                    "ios/release/SwiftGodot.framework": ""
                ]
            ]
        ]
        let gdExtension = GDExtension(
            name: "TestExtension",
            platforms: [Platform_iOS_Device()],
            archs: [.aarch64],
            configuration: .standard,
            binLocation: "bin",
            buildModes: [.release],
            platformDependencies: [:],
            swiftRuntimeDir: "swift"
        )
        try compareTscn(
            actual: gdExtension.tscnRepresentation,
            to: expectedResult
        )
    }
    
    private func compareTscn(actual: TSCN, to expected: TSCN) throws {
        let encoder = TSCNEncoder()
        let expectedString = try encoder.encode(tscn: expected)
        let actualString = try encoder.encode(tscn: actual)
        #expect(expectedString == actualString)
    }
}

