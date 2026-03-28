import Foundation
import Testing
@testable import sgint

@Suite
struct GDExtensionTests {

    @Test
    func testExtensionGenerationMac() throws {

        let expectedResult: String = """
        [configuration]
        entry_symbol = "swift_entry_point"
        compatibility_minimum = 4.2

        [libraries]
        macos.release.arm64 = "macos-aarch64/release/libTestExtension.dylib"
        macos.release.x86_64 = "macos-x86_64/release/libTestExtension.dylib"
        
        [dependencies]
        macos.release.arm64 = {"macos-aarch64/release/libSwiftGodot.dylib":""}
        macos.release.x86_64 = {"macos-x86_64/release/libSwiftGodot.dylib":""}
        """

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
        let tscn = gdExtension.tscnRepresentation
        let string = try TSCNEncoder().encode(tscn: tscn)
        #expect(expectedResult == string)
    }

}