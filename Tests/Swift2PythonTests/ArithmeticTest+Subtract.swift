//
//  Test.swift
//  Swift2Python
//
//  Created by Ben White on 5/5/26.
//


import Testing
import Logging
@testable import Swift2Python

extension ArithmeticTests {
    
    @Test("O-_001: Minus Operator Integer")
    func minusOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundIntA = try 77.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundIntB = try 22.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundIntA: PythonInterpreter.SafePythonObject = 6
            let unboundIntB: PythonInterpreter.SafePythonObject = 2
            
            let boundDouble = try 19.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = 2.25
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            
            // Integer-led subtraction should preserve integer results for int/bool combinations
            // regardless of whether each operand is bound to an interpreter or still deferred.
            let intCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound int - bound int", boundIntA, boundIntB, 55),
                ("bound int - unbound int", boundIntA, unboundIntB, 75),
                ("unbound int - bound int", unboundIntB, boundIntA, -75),
                ("unbound int - unbound int", unboundIntA, unboundIntB, 4),
                ("bound int - bound bool", boundIntA, boundTrue, 76),
                ("bound int - unbound bool", boundIntA, unboundTrue, 76),
                ("unbound int - bound bool", unboundIntA, boundTrue, 5),
                ("unbound int - unbound bool", unboundIntA, unboundTrue, 5)
            ]
            
            for (description, lhs, rhs, expected) in intCases {
                let result = lhs - rhs
                let roundTrip = try Int(result)
                #expect(roundTrip == expected, Comment(rawValue: description))
            }
            
            // Integer-led subtraction should promote to double when either side is a double,
            // while still covering bound/unbound combinations.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound int - bound double", boundIntA, boundDouble, 57.5),
                ("bound int - unbound double", boundIntA, unboundDouble, 74.75),
                ("unbound int - bound double", unboundIntA, boundDouble, -13.5),
                ("unbound int - unbound double", unboundIntA, unboundDouble, 3.75)
            ]
            
            for (description, lhs, rhs, expected) in doubleCases {
                let result = lhs - rhs
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
            
            // Chaining verifies the operator preserves left-to-right subtraction order while
            // threading the promoted result type through multiple mixed operands.
            let chainedResult = boundIntB - unboundIntB - unboundDouble - boundTrue
            let chainedRoundTrip = try Double(chainedResult)
            #expect(chainedRoundTrip.isCloseEnough(to: 16.75))
        }
    }
    
    @Test("O-_002: Minus Operator Double")
    func minusOperatorDouble() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDoubleA = try (-17.4).toSafePythonObject(interpreter: isolatedInterpreter)
            let boundDoubleB = try 22.6.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDoubleA: PythonInterpreter.SafePythonObject = 19.1
            let unboundDoubleB: PythonInterpreter.SafePythonObject = 1.6
            
            let boundInt = try 8.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = 3
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            // Double-led subtraction should stay in floating-point space for double/double,
            // double/int, and double/bool combinations across bound and unbound states.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound double - bound double", boundDoubleA, boundDoubleB, -40.0),
                ("bound double - unbound double", boundDoubleA, unboundDoubleA, -36.5),
                ("unbound double - bound double", unboundDoubleA, boundDoubleA, 36.5),
                ("unbound double - unbound double", unboundDoubleA, unboundDoubleB, 17.5),
                ("bound double - bound int", boundDoubleA, boundInt, -25.4),
                ("bound double - unbound int", boundDoubleA, unboundInt, -20.4),
                ("unbound double - bound int", unboundDoubleA, boundInt, 11.1),
                ("unbound double - unbound int", unboundDoubleA, unboundInt, 16.1),
                ("bound double - bound bool", boundDoubleA, boundTrue, -18.4),
                ("bound double - unbound bool", boundDoubleA, unboundFalse, -17.4),
                ("unbound double - bound bool", unboundDoubleA, boundTrue, 18.1),
                ("unbound double - unbound bool", unboundDoubleA, unboundFalse, 19.1)
            ]
            
            for (description, lhs, rhs, expected) in doubleCases {
                let result = lhs - rhs
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
            
            // Chaining keeps the left-to-right evaluation path active through repeated promotions.
            let chainedResult = unboundDoubleA - boundDoubleB - unboundDoubleB - boundDoubleA
            let chainedRoundTrip = try Double(chainedResult)
            #expect(chainedRoundTrip.isCloseEnough(to: 12.3))
        }
    }
    
    @Test("O-_004: Minus Operator Bool")
    func minusOperatorBool() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundFalse = try false.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let boundInt = try 9.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = 4
            
            let boundDouble = try 2.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = 7.5
            
            // Bool-led subtraction behaves like Python numeric subtraction, where bool participates
            // as 0/1. These cases cover bool/bool and bool/int paths for all success states.
            let intCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound bool - bound bool", boundTrue, boundFalse, 1),
                ("bound bool - unbound bool", boundTrue, unboundFalse, 1),
                ("unbound bool - bound bool", unboundTrue, boundFalse, 1),
                ("unbound bool - unbound bool", unboundTrue, unboundTrue, 0),
                ("bound bool - bound int", boundTrue, boundInt, -8),
                ("bound bool - unbound int", boundTrue, unboundInt, -3),
                ("unbound bool - bound int", unboundTrue, boundInt, -8),
                ("unbound bool - unbound int", unboundTrue, unboundInt, -3)
            ]
            
            for (description, lhs, rhs, expected) in intCases {
                let result = lhs - rhs
                let roundTrip = try Int(result)
                #expect(roundTrip == expected, Comment(rawValue: description))
            }
            
            // When a bool-led subtraction involves a double, the result should promote to double
            // while still treating the bool as 0/1.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound bool - bound double", boundTrue, boundDouble, -1.5),
                ("bound bool - unbound double", boundTrue, unboundDouble, -6.5),
                ("unbound bool - bound double", unboundTrue, boundDouble, -1.5),
                ("unbound bool - unbound double", unboundTrue, unboundDouble, -6.5)
            ]
            
            for (description, lhs, rhs, expected) in doubleCases {
                let result = lhs - rhs
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
        }
    }
    
    @Test("O-_005: PythonObject (async) subtract")
    func subtractPythonObject() async throws {
        let minuendA = try await 17.toPythonObject(interpreter: interpreter)
        let subtrahendA = try await 60.toPythonObject(interpreter: interpreter)
        let differenceA = try await minuendA.subtract(subtrahendA)
        let roundTripA = try await Int(differenceA)
        #expect(roundTripA == -43)
        
        let minuendB = try await 17.toPythonObject(interpreter: interpreter)
        let differenceB = try await minuendB.subtract(59)
        let roundTripB = try await Int(differenceB)
        #expect(roundTripB == -42)
        
        let minuendC = try await 17.toPythonObject(interpreter: interpreter)
        let differenceC = try await minuendC.subtract(59.7)
        let roundTripC = try await Double(differenceC)
        #expect(roundTripC.isCloseEnough(to: -42.7))
        
        let minuendD = try await true.toPythonObject(interpreter: interpreter)
        let differenceD = try await minuendD.subtract(false)
        let roundTripD = try await Int(differenceD)
        #expect(roundTripD == 1)
    }
    
    @Test("O-_006: PythonObject (async) subtract error checking")
    func subtractPythonObjectError() async throws {
        let boundDouble = try await 1.5.toPythonObject(interpreter: interpreter)
        let boundInt = try await 2.toPythonObject(interpreter: interpreter)
        let boundString = try await "abc".toPythonObject(interpreter: interpreter)
        let boundBool = try await true.toPythonObject(interpreter: interpreter)
        
        // Async PythonObject subtraction always goes through Python, so every invalid string-related
        // subtraction should surface as pythonException.
        let errorCases: [(String, PythonObject, any PendingPythonConvertible)] = [
            ("python double - string", boundDouble, "abc"),
            ("python int - string", boundInt, "abc"),
            ("python string - double", boundString, 1.5),
            ("python string - int", boundString, 2),
            ("python string - string", boundString, "def"),
            ("python string - bool", boundString, true),
            ("python bool - string", boundBool, "abc")
        ]
        
        for (description, lhs, rhs) in errorCases {
            let thrownError = await #expect(throws: PythonError.self, Comment(rawValue: description)) {
                _ = try await lhs.subtract(rhs)
            }
            
            if case .pythonException = thrownError {
                // expected
            } else {
                Issue.record("Expected .pythonException for \(description), but got \(thrownError)")
            }
        }
    }
    
    @Test("O-_010: safePythonObject subtraction error checking")
    func safeSubtractionErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDouble = try 1.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundInt = try 2.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundBool = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundInt: PythonInterpreter.SafePythonObject = 2
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let unboundBool: PythonInterpreter.SafePythonObject = true
            
            // Fully deferred invalid subtractions should throw the local typeError that matches
            // the operand order encoded in SafePythonObject.subtract(subtrahend:).
            let unboundTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound double - unbound string", unboundDouble, unboundString, "Double", "String"),
                ("unbound int - unbound string", unboundInt, unboundString, "Int", "String"),
                ("unbound string - unbound double", unboundString, unboundDouble, "String", "Double"),
                ("unbound string - unbound int", unboundString, unboundInt, "String", "Int"),
                ("unbound string - unbound string", unboundString, unboundString, "String", "String"),
                ("unbound string - unbound bool", unboundString, unboundBool, "String", "Bool"),
                ("unbound bool - unbound string", unboundBool, unboundString, "Bool", "String")
            ]
            
            for (description, lhs, rhs, expectedType1, expectedType2) in unboundTypeErrorCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.subtract(subtrahend: rhs)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "subtraction", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(thrownError)")
                }
            }
            
            // Once either side is bound, subtract(subtrahend:) delegates to Python. The same invalid
            // type pairs should therefore fail as safePythonException instead of the local typeError above.
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound double - unbound string", boundDouble, unboundString),
                ("unbound double - bound string", unboundDouble, boundString),
                ("bound double - bound string", boundDouble, boundString),
                ("bound int - unbound string", boundInt, unboundString),
                ("unbound int - bound string", unboundInt, boundString),
                ("bound int - bound string", boundInt, boundString),
                ("bound string - unbound double", boundString, unboundDouble),
                ("unbound string - bound double", unboundString, boundDouble),
                ("bound string - bound double", boundString, boundDouble),
                ("bound string - unbound int", boundString, unboundInt),
                ("unbound string - bound int", unboundString, boundInt),
                ("bound string - bound int", boundString, boundInt),
                ("bound string - unbound string", boundString, unboundString),
                ("unbound string - bound string", unboundString, boundString),
                ("bound string - bound string", boundString, boundString),
                ("bound string - unbound bool", boundString, unboundBool),
                ("unbound string - bound bool", unboundString, boundBool),
                ("bound string - bound bool", boundString, boundBool),
                ("bound bool - unbound string", boundBool, unboundString),
                ("unbound bool - bound string", unboundBool, boundString),
                ("bound bool - bound string", boundBool, boundString)
            ]
            
            for (description, lhs, rhs) in boundExceptionCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.subtract(subtrahend: rhs)
                }
                
                if case .safePythonException = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .safePythonException for \(description), but got \(thrownError)")
                }
            }
        }
    }
    
    
}



// Checklist of tests that pass.  Fill in the date when it runs correctly.

// [   date   ] : The date the test runs correctly and passes
// [yyyy-mm-dd] : Test ID : Test
//


// Subtraction

// [2026-05-05] : O-_001 : Subtract integer from integer SafePythonObject
// [2026-05-05] : O-_002 : Subtract integer from double SafePythonObject
// [2026-05-05] : O-_002 : Subtract double from double SafePythonObject
// [2026-05-05] : O-_002 : Subtract double from integer SafePythonObject
// [2026-05-05] : O-_001 : Subtract bool from integer SafePythonObject
// [2026-05-05] : O-_002 : Subtract bool from double SafePythonObject
// [2026-05-05] : O-_004 : Subtract bool from bool SafePythonObject

// [2026-05-05] : O-_001 : Subtract integer from integer SafePythonObject unbound
// [2026-05-05] : O-_002 : Subtract integer from double SafePythonObject unbound
// [2026-05-05] : O-_002 : Subtract double from double SafePythonObject unbound
// [2026-05-05] : O-_002 : Subtract double from integer SafePythonObject unbound
// [2026-05-05] : O-_001 : Subtract bool from integer SafePythonObject unbound
// [2026-05-05] : O-_002 : Subtract bool from double SafePythonObject unbound
// [2026-05-05] : O-_004 : Subtract bool from bool SafePythonObject unbound

// [2026-05-05] : O-_010 : Subtract string from integer SafePythonObject error handling
// [2026-05-05] : O-_010 : Subtract string from double SafePythonObject error handling
// [2026-05-05] : O-_010 : Subtract string from bool SafePythonObject error handling
// [2026-05-05] : O-_010 : Subtract integer from string SafePythonObject error handling
// [2026-05-05] : O-_010 : Subtract double from string SafePythonObject error handling
// [2026-05-05] : O-_010 : Subtract bool from string SafePythonObject error handling

// [2026-05-05] : O-_005 : Subtract PythonObject from PythonObject
// [2026-05-05] : O-_005 : Subtract PythonObject from Int
// [2026-05-05] : O-_005 : Subtract PythonObject from Double
// [2026-05-05] : O-_005 : Subtract PythonObject from Bool
// [2026-05-05] : O-_005 : Subtract PythonObject from String
// [2026-05-05] : O-_006 : Subtract PythonObject error handling
