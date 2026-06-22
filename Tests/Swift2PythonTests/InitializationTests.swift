//
//  InitializationTests.swift
//  Swift2Python
//
//  Created by Ben White on 3/7/26.
//

import Testing
import Logging
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
        try await runtime.initialize()

        return try await PythonInterpreter()
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

}
