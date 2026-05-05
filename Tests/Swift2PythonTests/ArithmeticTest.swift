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
    
    
    // MARK: O+_xxx Addition
    
    @Test("O+_001: Plus Operator Integer")
    func plusOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundIntA = try 77.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundIntB = try 22.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundIntA: PythonInterpreter.SafePythonObject = 6
            let unboundIntB: PythonInterpreter.SafePythonObject = 2
            
            let boundDouble = try 19.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = 2.25
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            
            // Integer-led addition should preserve integer results for int/bool combinations
            // regardless of whether each operand is bound to an interpreter or still deferred.
            let intCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound int + bound int", boundIntA, boundIntB, 99),
                ("bound int + unbound int", boundIntA, unboundIntB, 79),
                ("unbound int + bound int", unboundIntB, boundIntA, 79),
                ("unbound int + unbound int", unboundIntA, unboundIntB, 8),
                ("bound int + bound bool", boundIntA, boundTrue, 78),
                ("bound int + unbound bool", boundIntA, unboundTrue, 78),
                ("unbound int + bound bool", unboundIntA, boundTrue, 7),
                ("unbound int + unbound bool", unboundIntA, unboundTrue, 7)
            ]
            
            for (description, lhs, rhs, expected) in intCases {
                let result = lhs + rhs
                let roundTrip = try Int(result)
                #expect(roundTrip == expected, Comment(rawValue: description))
            }
            
            // Integer-led addition should promote to double when either side is a double,
            // while still covering bound/unbound combinations.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound int + bound double", boundIntA, boundDouble, 96.5),
                ("bound int + unbound double", boundIntA, unboundDouble, 79.25),
                ("unbound int + bound double", unboundIntA, boundDouble, 25.5),
                ("unbound int + unbound double", unboundIntA, unboundDouble, 8.25)
            ]
            
            for (description, lhs, rhs, expected) in doubleCases {
                let result = lhs + rhs
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
            
            // Chaining verifies the operator continues to thread the correct result type and order
            // across multiple mixed additions.
            let chainedResult = unboundDouble + boundIntB + unboundIntB + boundIntA
            let chainedRoundTrip = try Double(chainedResult)
            #expect(chainedRoundTrip.isCloseEnough(to: 103.25))
        }
    }
    
    @Test("O+_002: Plus Operator Double")
    func plusOperatorDouble() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDoubleA = try (-17.4).toSafePythonObject(interpreter: isolatedInterpreter)
            let boundDoubleB = try 22.6.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDoubleA: PythonInterpreter.SafePythonObject = 19.1
            let unboundDoubleB: PythonInterpreter.SafePythonObject = 1.6
            
            let boundInt = try 8.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = 3
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            // Double-led addition should stay in floating-point space for double/double,
            // double/int, and double/bool combinations across bound and unbound states.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound double + bound double", boundDoubleA, boundDoubleB, 5.2),
                ("bound double + unbound double", boundDoubleA, unboundDoubleA, 1.7),
                ("unbound double + bound double", unboundDoubleA, boundDoubleA, 1.7),
                ("unbound double + unbound double", unboundDoubleA, unboundDoubleB, 20.7),
                ("bound double + bound int", boundDoubleA, boundInt, -9.4),
                ("bound double + unbound int", boundDoubleA, unboundInt, -14.4),
                ("unbound double + bound int", unboundDoubleA, boundInt, 27.1),
                ("unbound double + unbound int", unboundDoubleA, unboundInt, 22.1),
                ("bound double + bound bool", boundDoubleA, boundTrue, -16.4),
                ("bound double + unbound bool", boundDoubleA, unboundFalse, -17.4),
                ("unbound double + bound bool", unboundDoubleA, boundTrue, 20.1),
                ("unbound double + unbound bool", unboundDoubleA, unboundFalse, 19.1)
            ]
            
            for (description, lhs, rhs, expected) in doubleCases {
                let result = lhs + rhs
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
            
            // Chaining keeps the left-to-right evaluation path active through repeated promotions.
            let chainedResult = unboundDoubleA + boundDoubleB + unboundDoubleB + boundDoubleA
            let chainedRoundTrip = try Double(chainedResult)
            #expect(chainedRoundTrip.isCloseEnough(to: 25.9))
        }
    }
    
    @Test("O+_003: Plus Operator String")
    func plusOperatorString() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundStringA = try "ABC".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundStringB = try "DEF".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundStringA: PythonInterpreter.SafePythonObject = "PP"
            let unboundStringB: PythonInterpreter.SafePythonObject = "QQ"
            
            // String addition is concatenation only, so these cases cover every successful
            // bound/unbound pairing and confirm operand order is preserved in the output.
            let stringCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String)] = [
                ("bound string + bound string", boundStringA, boundStringB, "ABCDEF"),
                ("bound string + unbound string", boundStringA, unboundStringB, "ABCQQ"),
                ("unbound string + bound string", unboundStringA, boundStringA, "PPABC"),
                ("unbound string + unbound string", unboundStringA, unboundStringB, "PPQQ")
            ]
            
            for (description, lhs, rhs, expected) in stringCases {
                let result = lhs + rhs
                let roundTrip = try String(result)
                #expect(roundTrip == expected, Comment(rawValue: description))
            }
            
            // Chaining confirms concatenation continues to respect left-to-right term order.
            let chainedResult = unboundStringA + boundStringB + unboundStringB + boundStringA
            let chainedRoundTrip = try String(chainedResult)
            #expect(chainedRoundTrip == "PPDEFQQABC")
        }
    }
    
    @Test("O+_004: Plus Operator Bool")
    func plusOperatorBool() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundFalse = try false.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let boundInt = try 9.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = 4
            
            let boundDouble = try 2.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = 7.5
            
            // Bool-led addition behaves like Python numeric addition, where bool participates
            // as 0/1. These cases cover bool/bool and bool/int paths for all success states.
            let intCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound bool + bound bool", boundTrue, boundFalse, 1),
                ("bound bool + unbound bool", boundTrue, unboundFalse, 1),
                ("unbound bool + bound bool", unboundTrue, boundFalse, 1),
                ("unbound bool + unbound bool", unboundTrue, unboundTrue, 2),
                ("bound bool + bound int", boundTrue, boundInt, 10),
                ("bound bool + unbound int", boundTrue, unboundInt, 5),
                ("unbound bool + bound int", unboundTrue, boundInt, 10),
                ("unbound bool + unbound int", unboundTrue, unboundInt, 5)
            ]
            
            for (description, lhs, rhs, expected) in intCases {
                let result = lhs + rhs
                let roundTrip = try Int(result)
                #expect(roundTrip == expected, Comment(rawValue: description))
            }
            
            // When a bool-led addition involves a double, the result should promote to double
            // while still treating the bool as 0/1.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound bool + bound double", boundTrue, boundDouble, 3.5),
                ("bound bool + unbound double", boundTrue, unboundDouble, 8.5),
                ("unbound bool + bound double", unboundTrue, boundDouble, 3.5),
                ("unbound bool + unbound double", unboundTrue, unboundDouble, 8.5)
            ]
            
            for (description, lhs, rhs, expected) in doubleCases {
                let result = lhs + rhs
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
        }
    }
    
    @Test("O+_005: PythonObject (async) add")
    func addPythongObject() async throws {
        
        let a = try await 17.toPythonObject(interpreter: interpreter)
        let b = try await 60.toPythonObject(interpreter: interpreter)
        let sum = try await a.add(b)
        let check = try await Int(sum)
        #expect(check == 77)
        
        let a2 = try await 17.toPythonObject(interpreter: interpreter)
        let sum2 = try await a2.add(59)
        let check2 = try await Int(sum2)
        #expect(check2 == 76)
        
        let a3 = try await 17.toPythonObject(interpreter: interpreter)
        let sum3 = try await a3.add(59.7)
        let check3 = try await Double(sum3)
        #expect(check3 == 76.7)
        
        let a4 = try await "FF".toPythonObject(interpreter: interpreter)
        let sum4 = try await a4.add("PP")
        let check4 = try await String(sum4)
        #expect(check4 == "FFPP")
    }
    
    @Test("O+_006: PythonObject (async) add error checking")
    func addPythongObjectError() async throws {
        
        let a = try await 17.toPythonObject(interpreter: interpreter)
        let b = try await "AA".toPythonObject(interpreter: interpreter)
    
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await a.add(b)
        }
        
        if case .pythonException = thrownError {
        } else {
            Issue.record("Expected .pythonException for Int.add(String), but got \(thrownError)")
        }
    }
    
    @Test("O+_010: safePythonObject addition error checking")
    func safeAdditionErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDouble = try 1.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundInt = try 2.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundBool = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundInt: PythonInterpreter.SafePythonObject = 2
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let unboundBool: PythonInterpreter.SafePythonObject = true
            
            // Fully deferred invalid additions should throw the local typeError that matches
            // the operand order encoded in SafePythonObject.add(_:)
            let unboundTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound double + unbound string", unboundDouble, unboundString, "Double", "String"),
                ("unbound int + unbound string", unboundInt, unboundString, "Int", "String"),
                ("unbound string + unbound double", unboundString, unboundDouble, "String", "Double"),
                ("unbound string + unbound int", unboundString, unboundInt, "String", "Int"),
                ("unbound string + unbound bool", unboundString, unboundBool, "String", "Bool"),
                ("unbound bool + unbound string", unboundBool, unboundString, "Bool", "String")
            ]
            
            for (description, lhs, rhs, expectedType1, expectedType2) in unboundTypeErrorCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.add(rhs)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "addition", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(thrownError)")
                }
            }
            
            // Once either side is bound, add(_:) delegates to Python. The same invalid type pairs
            // should therefore fail as safePythonException instead of the local typeError above.
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound double + unbound string", boundDouble, unboundString),
                ("unbound double + bound string", unboundDouble, boundString),
                ("bound int + unbound string", boundInt, unboundString),
                ("unbound int + bound string", unboundInt, boundString),
                ("bound string + unbound double", boundString, unboundDouble),
                ("unbound string + bound double", unboundString, boundDouble),
                ("bound string + unbound int", boundString, unboundInt),
                ("unbound string + bound int", unboundString, boundInt),
                ("bound string + unbound bool", boundString, unboundBool),
                ("unbound string + bound bool", unboundString, boundBool),
                ("bound bool + unbound string", boundBool, unboundString),
                ("unbound bool + bound string", unboundBool, boundString),
                ("bound string + bound int", boundString, boundInt),
                ("bound int + bound string", boundInt, boundString)
            ]
            
            for (description, lhs, rhs) in boundExceptionCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.add(rhs)
                }
                
                if case .safePythonException = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .safePythonException for \(description), but got \(thrownError)")
                }
            }
        }
    }
    
    
    // MARK: O-_xxx Subtraction
    
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

    // MARK: O/_xxx Division
    
    // MARK: O%_xxx Division
    
    // MARK: O**_xxx Division
}






// Checklist of tests that pass.  Fill in the date when it runs correctly.

// [   date   ] : The date the test runs correctly and passes
// [yyyy-mm-dd] : Test ID : Test
//


// Addition

// [2026-05-04] : O+_001 : Add integer to integer SafePythonObject
// [2026-05-04] : O+_002 : Add integer to double SafePythonObject
// [2026-05-04] : O+_002 : Add double to double SafePythonObject
// [2026-05-04] : O+_002 : Add double to integer SafePythonObject
// [2026-05-04] : O+_001 : Add bool to integer SafePythonObject
// [2026-05-04] : O+_002 : Add bool to double SafePythonObject
// [2026-05-04] : O+_003 : Add string to string SafePythonObject
// [2026-05-04] : O+_004 : Add bool to bool SafePythonObject

// [2026-05-04] : O+_001 : Add integer to integer SafePythonObject unbound
// [2026-05-04] : O+_002 : Add integer to double SafePythonObject unbound
// [2026-05-04] : O+_002 : Add double to double SafePythonObject unbound
// [2026-05-04] : O+_002 : Add double to integer SafePythonObject unbound
// [2026-05-04] : O+_001 : Add bool to integer SafePythonObject unbound
// [2026-05-04] : O+_002 : Add bool to double SafePythonObject unbound
// [2026-05-04] : O+_003 : Add string to string SafePythonObject unbound
// [2026-05-04] : O+_004 : Add bool to bool SafePythonObject unbound

// [2026-05-04] : O+_010 : Add string to integer SafePythonObject error handling
// [2026-05-04] : O+_010 : Add string to double SafePythonObject error handling
// [2026-05-04] : O+_010 : Add string to bool SafePythonObject error handling
// [2026-05-04] : O+_010 : Add integer to string SafePythonObject error handling
// [2026-05-04] : O+_010 : Add double to string SafePythonObject error handling
// [2026-05-04] : O+_010 : Add bool to string SafePythonObject error handling

// [2026-05-04] : O+_005 : Add PythonObject and PythongObject
// [2026-05-04] : O+_005 : Add PythonObject and Int
// [2026-05-04] : O+_005 : Add PythonObject and Double
// [2026-05-04] : O+_005 : Add PythonObject and Bool
// [2026-05-04] : O+_005 : Add PythonObject and String
// [2026-05-04] : O+_006 : Add PythonObject error handling


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
