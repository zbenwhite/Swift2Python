//
//  InitializationTests.swift
//  Swift2Python
//
//  Created by Ben White on 3/7/26.
//

import Testing
import Logging
import Foundation
@testable import Swift2Python

enum TestSupport {
    static let setupLogging: Void = {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .trace
            return handler
        }
    }()

    static let sharedInterpreterTask: Task<PythonInterpreter, Error> = Task {
        _ = setupLogging

        let runtime = PythonRuntime.shared
        return try await runtime.interpreter()
    }
}

struct InitializationTests {
    
    private static let sharedInterpreterTask = TestSupport.sharedInterpreterTask
    
    let interpreter: PythonInterpreter
    
    init() async throws {
        self.interpreter = try await Self.sharedInterpreterTask.value
    }

    @Test("Python runtime can be initialized")
    func basicInitialization() async throws {
        
        var logger = Logger(label: "swift2python.PythonRuntime")
        logger.logLevel = .debug // Override for just this test
        
        let runtime = PythonRuntime.shared
        
        // The shared test interpreter initializes the singleton runtime before tests run.
        #expect(await runtime.isInitialized == true)
        #expect(await runtime.pythonVersion != nil)
        #expect(await runtime.pythonVersionString != nil)
        
        // Initialization is idempotent after the runtime is already available.
        try await runtime.initialize()
        #expect(await runtime.isInitialized == true)
        #expect(await runtime.pythonVersion != nil)
    }
    
    @Test("PythonRuntime hands out a cached default interpreter")
    func runtimeDefaultInterpreterIsCached() async throws {
        let runtime = PythonRuntime.shared
        let first = try await runtime.interpreter()
        let second = try await runtime.interpreter()
        
        #expect(first === second)
        #expect(first === interpreter)
    }
    
    @Test("Runtime library resolution prefers explicit path, then environment, then defaults")
    func pythonLibraryResolutionPrecedence() {
        let environment = [
            PythonRuntime.libraryEnvironmentVariable: "/env/libpython.dylib"
        ]
        
        #expect(PythonRuntime.pythonLibraryCandidatePaths(
            explicitLibraryPath: "/explicit/libpython.dylib",
            environment: environment
        ) == ["/explicit/libpython.dylib"])
        
        #expect(PythonRuntime.pythonLibraryCandidatePaths(
            explicitLibraryPath: nil,
            environment: environment
        ) == ["/env/libpython.dylib"])
        
        let defaults = PythonRuntime.pythonLibraryCandidatePaths(
            explicitLibraryPath: "   ",
            environment: [PythonRuntime.libraryEnvironmentVariable: "\n"]
        )
        #expect(defaults.count > 1)
    }
    
    @Test("Runtime reads Swift2Python PYTHONPATH override")
    func swift2PythonPythonPathOverrideResolution() {
        #expect(PythonRuntime.swift2PythonPythonPath(environment: [
            PythonRuntime.pythonPathEnvironmentVariable: "/project/python:/project/vendor"
        ]) == "/project/python:/project/vendor")
        
        #expect(PythonRuntime.swift2PythonPythonPath(environment: [
            PythonRuntime.pythonPathEnvironmentVariable: "  "
        ]) == nil)
        
        #expect(PythonRuntime.swift2PythonPythonPath(environment: [:]) == nil)
    }
    
    @Test("Runtime expands wildcard library path candidates before loading")
    func pythonLibraryResolutionExpandsWildcardCandidates() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("Swift2PythonRuntimeGlob-\(UUID().uuidString)")
        let versionDirectory = root.appendingPathComponent("3.13.7")
        let libraryURL = versionDirectory.appendingPathComponent("libpython3.13.dylib")
        
        try FileManager.default.createDirectory(
            at: versionDirectory,
            withIntermediateDirectories: true
        )
        FileManager.default.createFile(atPath: libraryURL.path, contents: Data())
        defer {
            try? FileManager.default.removeItem(at: root)
        }
        
        let pattern = root
            .appendingPathComponent("3.13.*")
            .appendingPathComponent("libpython3.13.dylib")
            .path
        
        #expect(PythonRuntime.expandedPythonLibraryCandidatePaths(
            explicitLibraryPath: nil,
            environment: [PythonRuntime.libraryEnvironmentVariable: pattern]
        ) == [libraryURL.path])
    }
    
    @Test("Runtime default library candidates include Linux libpython locations")
    func pythonLibraryDefaultsIncludeLinuxLocations() {
        let candidates = PythonRuntime.pythonLibraryCandidatePaths(
            explicitLibraryPath: nil,
            environment: [:]
        )
        
        #expect(candidates.contains("/usr/local/lib/libpython3.13.so"))
        #expect(candidates.contains("/usr/lib/*/libpython3.13.so.1.0"))
        #expect(candidates.contains("/usr/lib64/libpython3.13.so"))
    }

}
