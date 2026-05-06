//
//  ArithmeticTest.swift
//  Swift2Python
//
//  Created by Ben White on 4/18/26.
//

import Testing
import Logging
@testable import Swift2Python

// Need this for testing double arithmetic results

extension Double {  // or Float / BinaryFloatingPoint where appropriate
    func isCloseEnough(
        to other: Double,
        relativeTolerance: Double = .ulpOfOne.squareRoot(),
        absoluteToleranceNearZero: Double = .ulpOfOne.squareRoot()
    ) -> Bool {
        // Exact equality shortcut (handles infinities, NaNs, etc.)
        if self == other { return true }
        
        let diff = abs(self - other)
        
        // Near zero: use absolute tolerance
        if self.isZero || other.isZero || diff < absoluteToleranceNearZero {
            return diff < absoluteToleranceNearZero
        }
        
        // Otherwise: relative tolerance (scale-invariant)
        let scale = max(abs(self), abs(other))
        return diff <= relativeTolerance * scale
    }
}


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
    
    
    
    // MARK: O-_xxx Subtraction
    
    
    // MARK: O*_xxx Multiplication
    
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
}




// Multiplication


// Division


// Modulus


// Exponentiation
