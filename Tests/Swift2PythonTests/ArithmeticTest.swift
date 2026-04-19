//
//  ArithmeticTest.swift
//  Swift2Python
//
//  Created by Ben White on 4/18/26.
//

import Testing
import Logging
@testable import Swift2Python

@Suite("Arithmetic Tests")
struct ArithmeticTests {
    
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
    
    
    // MARK: O+_xxx Addition Tests
    
    @Test("O+_001: Plus Operator Integer")
    func plusOperatorInteger() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Int = 77
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            let safePyObj2 = safePyObj + 19
            let roundTrip = try Int(safePyObj2)
            #expect(roundTrip == 96)
        }
    }
    
    
    // MARK: O-_xxx Subtraction Tests
    
    @Test("O-_001: Minus Operator Integer")
    func minusOperatorInteger() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Int = 77
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            let safePyObj2 = safePyObj - 19
            let roundTrip = try Int(safePyObj2)
            #expect(roundTrip == 58)
        }
    }
    
    // MARK: O*_xxx Multiplication Tests
    
    @Test("O*_001: Multiplication Operator Integer")
    func multiplicationOperatorInteger() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Int = 77
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            let safePyObj2 = safePyObj * 3
            let roundTrip = try Int(safePyObj2)
            #expect(roundTrip == 231)
        }
    }

    // MARK: O/_xxx Division Tests
    
    // MARK: O%_xxx Division Tests
    
    // MARK: O**_xxx Division Tests
}
