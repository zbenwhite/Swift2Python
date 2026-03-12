//
//  InitializationTests.swift
//  Swift2Python
//
//  Created by Ben White on 3/7/26.
//

import Testing
import Logging
@testable import Swift2Python


// This runs once when the test process starts
private let setupLogging: Void = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = .debug
        return handler
    }
}()

struct InitializationTests {
    
    init() {
        _ = setupLogging
    }

    @Test("Python runtime can be initialized")
    func basicInitialization() async throws {
        
        var logger = Logger(label: "swift2python.PythonRuntime")
        logger.logLevel = .debug // Override for just this test
        
        let runtime = PythonRuntime.shared
        
        // Before initialization
        let preInitialized = await runtime.isInitialized
        #expect(preInitialized == false)
        #expect(await runtime.pythonVersion == nil)
        #expect(await runtime.pythonVersionString == nil)
        
        // This is usually the very first call in most Python interop libraries
        try await runtime.initialize()
        
        
        // After successful initialization
        let postInitialized = await runtime.isInitialized
        #expect(postInitialized == true)
        #expect(await runtime.pythonVersion != nil)
    }

}
