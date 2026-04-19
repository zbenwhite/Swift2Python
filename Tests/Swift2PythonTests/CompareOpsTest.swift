//
//  CompareOpsTest.swift
//  Swift2Python
//
//  Created by Ben White on 4/18/26.
//

import Testing
import Logging
@testable import Swift2Python

@Suite("Comparison Operations Tests")
struct CompareOpsTests {

    private static let setupLogging: Void = {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .trace
            return handler
        }
    }()
    
    private static let sharedInterpreterTask: Task<PythonInterpreter, Error> = Task {
        _ = setupLogging
        
        // Initialize the runtime
        let runtime = PythonRuntime.shared
        try await runtime.initialize()
        
        // Create and return the single shared interpreter
        return try await PythonInterpreter()
    }
    
    let interpreter: PythonInterpreter
    
    init() async throws {
        self.interpreter = try await Self.sharedInterpreterTask.value
    }
    
    
    // MARK: O<_xxx Less Than Tests
    // MARK: O<=_xxx Less Than or Equal Tests
    // MARK: O<_xxx Greater Than Tests
    // MARK: O<=_xxx Greater Than or Equal Tests
    // MARK: O==_xxx Equality Tests
    // MARK: O!=_xxx Not Equals Tests
}
