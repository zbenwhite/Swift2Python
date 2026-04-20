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
    
    
    // MARK: O+_xxx Addition Tests
    
    @Test("O+_001: Plus Operator Integer")
    func plusOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            
            // Add integer to integer SafePythonObject
            let value: Int = 77
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            let safePyObj2 = safePyObj + 19
            let roundTrip = try Int(safePyObj2)
            #expect(roundTrip == 96)
            
            // Add integer to integer SafePythonObject other order
            let valueA: Int = 77
            let safePyObjA = try valueA.toSafePythonObject(interpreter: isolatedInterpreter)
            let safePyObj2A = 19 + safePyObjA
            let roundTripA = try Int(safePyObj2A)
            #expect(roundTripA == 96)
            
            // Add multiple items
            let valueB: Int = 22
            let safePyObjB = try valueB.toSafePythonObject(interpreter: isolatedInterpreter)
            let safePyObj2B = 19 + safePyObjB + 2 + safePyObjA // 19 + 22 + 2 + 77 = 120
            let roundTripB = try Int(safePyObj2B)
            #expect(roundTripB == 120)
            
            // Add integer SafePythonObject to integer SafePythonObject
            let safePyObj2C = safePyObjB + safePyObjA   // 22 + 77 = 99
            let roundTripC = try Int(safePyObj2C)
            #expect(roundTripC == 99)
        }
    }
    
    @Test("O+_002: Plus Operator Double")
    func plusOperatorDouble() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            
            // Add double to double SafePythonObject
            let value: Double = -17.4
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            let safePyObj2 = safePyObj + 19.9  // -17.4 + 19.9 = 2.5
            let roundTrip = try Double(safePyObj2)
            #expect(roundTrip == 2.5)
            
            // Add double to double SafePythonObject other order
            let valueA: Double = -17.4
            let safePyObjA = try valueA.toSafePythonObject(interpreter: isolatedInterpreter)
            let safePyObj2A = 19.1 + safePyObjA  // -17.4 + 19.1 = 1.7
            let roundTripA = try Double(safePyObj2A)
            #expect(roundTripA.isCloseEnough(to: 1.7))
            
            // Add multiple double items
            let valueB: Double = 22.6
            let safePyObjB = try valueB.toSafePythonObject(interpreter: isolatedInterpreter)
            let safePyObj2B = 19.0 + safePyObjB + 1.6 + safePyObjA // 19.0 + 22.6 + 1.6 + -17.4 = 25.8
            let roundTripB = try Double(safePyObj2B)
            #expect(roundTripB.isCloseEnough(to: 25.8))
            
            // Add double SafePythonObject to double SafePythonObject
            let safePyObj2C = safePyObjB + safePyObjA   // 22.6 + -17.4 = 5.2
            let roundTripC = try Double(safePyObj2C)
            #expect(roundTripC.isCloseEnough(to: 5.2))
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






// Checklist of tests that pass.  Fill in the date when it runs correctly.

// [   date   ] : The date the test runs correctly and passes
// [yyyy-mm-dd] : Test ID : Test
//


// Addition

// [2026-04-19] : O+_001 : Add integer to integer SafePythonObject
// [          ] : O+_xxx : Add integer to double SafePythonObject
// [2026-04-19] : O+_002 : Add double to double SafePythonObject
// [          ] : O+_xxx : Add double to integer SafePythonObject
// [          ] : O+_xxx : Add bool to integer SafePythonObject
// [          ] : O+_xxx : Add bool to double SafePythonObject
// [          ] : O+_xxx : Add string to string SafePythonObject

// [          ] : O+_xxx : Add integer to integer SafePythonObject unbound
// [          ] : O+_xxx : Add integer to double SafePythonObject unbound
// [          ] : O+_xxx : Add double to double SafePythonObject unbound
// [          ] : O+_xxx : Add double to integer SafePythonObject unbound
// [          ] : O+_xxx : Add bool to integer SafePythonObject unbound
// [          ] : O+_xxx : Add bool to double SafePythonObject unbound
// [          ] : O+_xxx : Add string to string SafePythonObject unbound

// [          ] : O+_xxx : Add string to integer SafePythonObject error handling
// [          ] : O+_xxx : Add string to double SafePythonObject error handling
// [          ] : O+_xxx : Add string to bool SafePythonObject error handling
// [          ] : O+_xxx : Add integer to string SafePythonObject error handling
// [          ] : O+_xxx : Add double to string SafePythonObject error handling
// [          ] : O+_xxx : Add bool to string SafePythonObject error handling


// [          ] : O+_xxx : Add in place integer to integer SafePythonObject
// [          ] : O+_xxx : Add in place integer to double SafePythonObject
// [          ] : O+_xxx : Add in place double to double SafePythonObject
// [          ] : O+_xxx : Add in place double to integer SafePythonObject
// [          ] : O+_xxx : Add in place bool to integer SafePythonObject
// [          ] : O+_xxx : Add in place bool to double SafePythonObject
// [          ] : O+_xxx : Add in place string to string SafePythonObject

// [          ] : O+_xxx : Add in place to integer SafePythonObject unbound
// [          ] : O+_xxx : Add in place to double SafePythonObject unbound
// [          ] : O+_xxx : Add in place double to double SafePythonObject unbound
// [          ] : O+_xxx : Add in place double to integer SafePythonObject unbound
// [          ] : O+_xxx : Add in place bool to integer SafePythonObject unbound
// [          ] : O+_xxx : Add in place bool to double SafePythonObject unbound
// [          ] : O+_xxx : Add in place string to string SafePythonObject unbound

// [          ] : O+_xxx : Add in place string to integer SafePythonObject error handling
// [          ] : O+_xxx : Add in place string to double SafePythonObject error handling
// [          ] : O+_xxx : Add in place string to bool SafePythonObject error handling
// [          ] : O+_xxx : Add in place integer to string SafePythonObject error handling
// [          ] : O+_xxx : Add in place double to string SafePythonObject error handling
// [          ] : O+_xxx : Add in place bool to string SafePythonObject error handling

// Subtraction


// [          ] : O-_xxx : Subtract integer from integer SafePythonObject
// [          ] : O-_xxx : Subtract integer from double SafePythonObject
// [          ] : O-_xxx : Subtract double from double SafePythonObject
// [          ] : O-_xxx : Subtract double from integer SafePythonObject
// [          ] : O-_xxx : Subtract bool from integer SafePythonObject
// [          ] : O-_xxx : Subtract bool from double SafePythonObject
// [          ] : O-_xxx : Subtract string from string SafePythonObject


// Multiplication


// Division


// Modulus


// Exponentiation

