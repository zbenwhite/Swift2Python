//
//  BitwiseOpsTest.swift
//  Swift2Python
//
//  Created by Ben White on 4/18/26.
//

import Testing
import Logging
@testable import Swift2Python

@Suite("Bitwise Operations Tests")
struct BitwiseOpsTests {

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
    
    
    // MARK: O&_xxx Bitwise AND Tests
    // MARK: O|_xxx Bitwise OR Tests
    // MARK: O^_xxx Bitwise XOR Tests
    // MARK: O~_xxx Bitwise NOT Tests
}
